#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") Then
		FillInBasedOnIntangibleAsset(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4") Then
		FillInBasedOnAcceptanceForAccountingOrEnteringBalances(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	IntangibleAssetsInitialRecognitionLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByIA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	CheckHeaderDetails_(AuxiliaryAttributes, Cancel);
	CheckDetailsAndExpenses(ItemDetailsParameters, CheckedAttributes, Cancel);
	VerifyBankingDetailsWithSpecifiedPresentation(AttributesNotToCheck, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	IntangibleAssetsInitialRecognitionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		BlockData_();
		NonCurrentAssetsInternal.CheckPossibilityOfAcceptingIAForAccounting(ThisObject, Cancel, True);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	
	FillInBankingDetailsBeforeWrite();
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	IntangibleAssetsInitialRecognitionLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IntangibleAssetsInitialRecognitionLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
	IntangibleAssetsInitialRecognitionLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IntangibleAssetsInitialRecognitionLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IntangibleAssetsInitialRecognitionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If Not ValueIsFilled(FinancialAccountingGroup) Then
		If KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
			CapitalAssetKind = Enums.KindsOfNonCurrentAssets.RD;
		Else
			CapitalAssetKind = Enums.KindsOfNonCurrentAssets.IA;
		EndIf;
		FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(CapitalAssetKind);
	EndIf;
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		ExpenseRecordMethodAC, 
		ExpenseItemAccounting, 
		ExpensesDimensionAccounting, 
		DepartmentACC, 
		LineOfBusinessBookkeeping, 
		BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping);
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		ExpenseRecordMethodTA, 
		ExpenseItemTaxAccounting, 
		ExpensesDimensionTaxAccounting, 
		BusinessUnitTaxAccounting, 
		LineOfBusinessTaxAccounting, 
		BusinessUnitAndLineOfBusinessMatchAccountingDataTaxAccounting);
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		MethodForReflectingMaExpenses, 
		ExpenseItemManagementAccounting, 
		ExpensesDimensionManagementAccounting, 
		BusinessUnitManagementAccounting, 
		LineOfBusinessManagementAccounting, 
		BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting);
	
EndProcedure

Procedure BlockData_()
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialIntangibleAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("IntangibleAsset", IntangibleAsset);
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsRegistrationPlace");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("IntangibleAsset", IntangibleAsset);
	
	Block.Lock();
	
EndProcedure

Procedure CheckHeaderDetails_(AuxiliaryAttributes, Cancel)

	CheckOrderDoNotTakeIntoAccountIncludeInExpenses(Cancel);
	
	NonCurrentAssetsInternal.CheckProcedureForGeneratingIACost(ThisObject, Cancel);
	
	ResidualValueTemplate = NStr("vi = 'Giá trị thanh lý phải nhỏ hơn %1 %2';
								|ru = 'Ликвидационная стоимость должна быть меньше %1 %2';
								|en = 'The residual value must be less than %1 %2'; fa = 'The residual value must be less than %1 %2';
								|it = 'The residual value must be less than %1 %2';
								|pl = 'The residual value must be less than %1 %2';
								|tr = 'Tasfiye değeri %1 %2değerinden az olmalıdır'");
		
	If ResidualValueLocal >= InitialCostLocalAccounting 
		And InitialCostLocalAccounting <> 0
		And PostInAccounting Then
		
		MessageText = StrTemplate(ResidualValueTemplate, InitialCostLocalAccounting, AuxiliaryAttributes.ComplCurrency);
		Common.MessageToUser(MessageText, ThisObject, "ResidualValueLocal", "", Cancel);
		
	EndIf;
	
	If ResidualValueMan >= InitialCostMA 
		And InitialCostMA <> 0
		And RecordInManAccounting
		And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
			Or AuxiliaryAttributes.CurrencyOfMan <> AuxiliaryAttributes.ComplCurrency) Then
		
		MessageText = StrTemplate(ResidualValueTemplate, InitialCostMA, AuxiliaryAttributes.CurrencyOfMan);
		Common.MessageToUser(MessageText, ThisObject, "ResidualValueMan", "", Cancel);
		
	EndIf;
		
EndProcedure

Procedure CheckDetailsAndExpenses(ItemDetailsParameters, CheckedAttributes, Cancel)

	ItemsAndDimensionsSelectionParameters = Documents.IntangibleAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemAccounting", AccountingProcedureAC, "ACC", Cancel);
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemTaxAccounting", AccountingProcedureTA, "TA", Cancel);
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemManagementAccounting", AccountingProcedureMA, "MA", Cancel);
	
EndProcedure

Procedure VerifyBankingDetailsWithSpecifiedPresentation(AttributesNotToCheck, Cancel)

	If KindOfAccountingObject <> Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
		Return;
	EndIf;
	
	// Checking the details of which the representation differs from what is specified in the metadata.
	
	AttributesList = New Structure;
	AttributesList.Insert("IntangibleAsset", NStr("vi = 'Chi phí nghiên cứu, triển khai';
													|ru = 'Расходы на НИОКР';
													|en = 'R&D expenses'; fa = 'هزینه‌های تحقیق و توسعه';
													|it = 'Spese per Ricerca e Sviluppo';
													|pl = 'Wydatki na R&D';
													|tr = 'Ar-Ge giderleri'"));
	AttributesList.Insert("DepreciationMethodAccounting", NStr("vi = 'Phương thức ghi giảm chi phí (kế toán doanh nghiệp)';
																|ru = 'Способ списания расходов (бухгалтерский учет)';
																|en = 'Expense write-off method (local accounting)'; fa = 'Expense write-off method (local accounting)';
																|it = 'Metodo di storno delle spese (contabilità)';
																|pl = 'Sposób spisania rozchodów (ewidencja księgowa)';
																|tr = 'Giderlerin mahsup edilmesi yöntemi (muhasebe)'"));
	AttributesList.Insert("DepreciationAccrualMethodManagementAccounting", NStr("vi = 'Phương pháp xóa chi phí (kế toán quản trị)';
																				|ru = 'Способ списания расходов (управленческий учет)';
																				|en = 'Expense write-off method (management accounting)'; fa = 'Expense write-off method (management accounting)';
																				|it = 'Modo di cancellazione delle uscite (contabilità gestionale)';
																				|pl = 'Sposób wyksięgowania wydatków (ewidencja administracyjna)';
																				|tr = 'Giderlerin mahsup edilme yöntemi (yönetim muhasebesi)'"));
	AttributesList.Insert("AccountingProcedureAC", NStr("vi = 'Trình tự ghi giảm (kế toán doanh nghiệp)';
														|ru = 'Порядок списания (бухгалтерский учет)';
														|en = 'Write-off procedure (local accounting)'; fa = 'Write-off procedure (local accounting)';
														|it = 'Ordine di storno (contabilità)';
														|pl = 'Procedura spisania (ewidencja księgowa)';
														|tr = 'Yazma prosedürü (muhasebe)'"));
	AttributesList.Insert("AccountingProcedureMA", NStr("vi = 'Thủ tục ghi giảm (kế toán quản trị)';
														|ru = 'Порядок списания (управленческий учет)';
														|en = 'Write-off procedure (management accounting)'; fa = 'Write-off procedure (management accounting)';
														|it = 'Ordine di cancellazione (contabilità gestionale)';
														|pl = 'Sposób wyksięgowania (ewidencja administracyjna)';
														|tr = 'Yazma prosedürü (yönetim muhasebesi)'"));
	
	IntangibleAssetsInitialRecognitionLocalization.AddDetailsToListWithSpecifiedPresentation(AttributesList);
	
	MessageTemplate = NStr("vi = 'Chưa điền trường ""%1""';
							|ru = 'Поле ""%1"" не заполнено';
							|en = 'Field ""%1"" is blank'; fa = 'Field ""%1"" is blank';
							|it = 'Il campo ""%1"" non è compilato';
							|pl = 'Pole ""%1"" nie jest wypełnione';
							|tr = '""%1"" alanı doldurulmadı.'");
	For Each AttributeDetails In AttributesList Do
		If AttributesNotToCheck.Find(AttributeDetails.Key) <> Undefined Then
			Continue;
		EndIf;
		If Not ValueIsFilled(ThisObject[AttributeDetails.Key]) Then
			MessageText = StrTemplate(MessageTemplate, AttributeDetails.Value);
			CommonClientServer.MessageToUser(MessageText, ThisObject, AttributeDetails.Key,, Cancel); 
		EndIf; 
		AttributesNotToCheck.Add(AttributeDetails.Key);
	EndDo; 
	
EndProcedure

Procedure CheckOrderDoNotTakeIntoAccountIncludeInExpenses(Cancel)
	
	CheckCompleted = IntangibleAssetsInitialRecognitionLocalization.CheckOrderDoNotTakeIntoAccountIncludeInExpenses(ThisObject, Cancel);
	If CheckCompleted Then
		Return;
	EndIf;
	
	If (AccountingProcedureMA = Enums.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses
			Or Not RecordInManAccounting)
		And (AccountingProcedureAC = Enums.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses
			Or Not PostInAccounting) 
		And (RecordInManAccounting
			Or PostInAccounting) Then
		
		If PostInAccounting Then
			Field = "AccountingProcedureAC";
		Else
			Field = "AccountingProcedureMA";
		EndIf;
		
		MessageText = NStr("vi = 'Không hỗ trợ chọn trình tự kế toán ""Không tiếp nhận vào kế toán, đưa vào chi phí"" ngay trong toàn bộ dạng kế toán. Một trong số các dạng kế toán cần có trình tự kế toán khác.';
							|ru = 'Не поддерживается выбор порядка учета ""Не принимать к учету, включить в расходы"" сразу во всех учетах. В одном из учетов должен быть другой порядок учета.';
							|en = 'Cannot select the ""Do not recognize, add to expenses"" accounting procedure in all accountings at the same time. One of the accountings must have a different accounting procedure.'; fa = 'Cannot select the ""Do not recognize, add to expenses"" accounting procedure in all accountings at the same time. One of the accountings must have a different accounting procedure.';
							|it = 'Не поддерживается выбор порядка учета ""Не принимать к учету, включить в расходы"" сразу во всех учетах. В одном из учетов должен быть другой порядок учета.';
							|pl = 'Cannot select the ""Do not recognize, add to expenses"" accounting procedure in all accountings at the same time. One of the accountings must have a different accounting procedure.';
							|tr = '""Kayda alma, giderlere dahil et"" muhasebe sırası seçimi tüm hesaplarda aynı anda desteklenmez. Hesaplardan biri farklı bir muhasebe sırasına sahip olmalıdır.'");
		Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		
	EndIf;
	
EndProcedure

Function AuxiliaryAttributes()

	DateOfParameters = EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()));

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", PostInAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", RecordInTA);
	AuxiliaryAttributes.Insert("BusinessOperation", BusinessOperation);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	AuxiliaryAttributes.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", AuxiliaryAttributes.CurrencyOfMan = AuxiliaryAttributes.ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"UseAccountingByAreasOfActivity", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));

	AuxiliaryAttributes.Insert(
		"ThereIsCostAccounting", 
		CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters, False));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, DateOfParameters));
		
	AuxiliaryAttributes.Insert(
		"AccountPolicySettings", 
		AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Organization, DateOfParameters));

	AuxiliaryAttributes.Insert(
		"ThereAreRelatedCompanies", 
		Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization));
	
	IntangibleAssetsInitialRecognitionLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);

	Return AuxiliaryAttributes;
	
EndFunction

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
		And Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		InitialCostMA = InitialCostLocalAccounting;
		ResidualValueMan = ResidualValueLocal;
	EndIf; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByIA(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "TargetFinancing");

EndProcedure

#Region FillType

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("Date") Then
		Date = Basis.Date;
	EndIf;
	
	If Basis.Property("Organization")
		And ValueIsFilled(Basis.Organization) Then
		Organization = Basis.Organization;
	EndIf;

	If Basis.Property("IntangibleAsset") Then
		
		FillInBasedOnIntangibleAsset(Basis.IntangibleAsset);
		
	ElsIf Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.IntangibleAssetsPhysicalCount") Then
		
		FillInBasedOnInventory(Basis);
		
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnIntangibleAsset(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder,KindOfAccountingObject");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể tiếp nhận vào kế toán TSCĐ vô hình trên cơ sở nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Принятие к учету НМА на основании группы НМА невозможно.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot recognize intangible assets based on intangible assets group.
			|Select intangible assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot recognize intangible assets based on intangible assets group.
			|Select intangible assets. To expand the group, press Ctrl+Down.';
			|it = 'Registrazione nella contabilità dei beni immateriali in base al gruppo Beni Immateriali non è possibile. 
			|Selezionate il bene immateriale. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przyjecie do ewidencji wartości niematerialnych na podstawie grupy wartości niematerialnych jest niemożliwe.
			|Wybierz wartości niematerialne. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
			|tr = 'Maddi olmayan varlık grubu bazında maddi olmayan varlıklar - ilk tahakkuk işlemi mümkün değildir. 
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	IntangibleAsset = Basis;	
	
	InitialInformation = Catalogs.IntangibleAssets.InitialInformation(Basis, Date);
	If ValueIsFilled(InitialInformation.DocumentOfRecognitionAccounting) 
		And Not ValueIsFilled(InitialInformation.DocumentOfRecognitionManagementAccounting)
		And (TypeOf(InitialInformation.DocumentOfRecognitionAccounting) = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4")
			Or TypeOf(InitialInformation.DocumentOfRecognitionAccounting) = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4")) Then
			
		FillInBasedOnAcceptanceForAccountingOrEnteringBalances(InitialInformation.DocumentOfRecognitionAccounting, Basis);
		Return;
		
	ElsIf ValueIsFilled(InitialInformation.DocumentOfRecognitionManagementAccounting) 
		And Not ValueIsFilled(InitialInformation.DocumentOfRecognitionAccounting)
		And (TypeOf(InitialInformation.DocumentOfRecognitionManagementAccounting) = Type("DocumentRef.IntangibleAssetsInitialRecognition2_4")
			Or TypeOf(InitialInformation.DocumentOfRecognitionManagementAccounting) = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4")) Then
			
		FillInBasedOnAcceptanceForAccountingOrEnteringBalances(InitialInformation.DocumentOfRecognitionManagementAccounting, Basis);
		Return;
		
	ElsIf InitialInformation.StateOfTheUU = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
		And (InitialInformation.BUState = Enums.IntangibleAssetsStates.PostedInFinancialAccounting
			Or Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept()) Then
		
		MessageText = StrTemplate(NStr("vi = 'tài sản cố định vô hình ""%1"" đã được tính đến.';
										|ru = 'Нематериальный актив ""%1"" уже принят к учету.';
										|en = 'The ""%1"" intangible asset is already recognized.'; fa = 'The ""%1"" intangible asset is already recognized.';
										|it = 'Il bene immateriale ""%1"" è già stato registrato nella contabilità.';
										|pl = 'Aktywa niematerialne ""%1"" zostały już przyjęte do ewidencji.';
										|tr = 'Maddi olmayan duran varlık ""%1"" zaten muhasebeye alınmıştır.'"), String(Basis));
		Raise MessageText;
		
	EndIf; 

	KindOfAccountingObject = DetailsOfFoundation.KindOfAccountingObject;
	
	Documents.IntangibleAssetsInitialRecognition2_4.FillInCost(ThisObject);
	
EndProcedure

Procedure FillInBasedOnAcceptanceForAccountingOrEnteringBalances(Basis, FilterIntangibleAsset = Undefined)

	BaseObject = Basis.GetObject();
	
	If TypeOf(Basis) = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4") Then
		IAString = BaseObject.IA.Find(FilterIntangibleAsset, "IntangibleAsset");
		FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
		FillPropertyValues(ThisObject, IAString);
		IntangibleAsset = FilterIntangibleAsset;
	Else
		FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	EndIf;
	
	DocumentInAnotherAccounting = Basis;
	
	If NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		PostInAccounting = Not BaseObject.PostInAccounting;
		RecordInTA = Not BaseObject.RecordInTA;
		RecordInManAccounting = Not BaseObject.RecordInManAccounting;
	Else	
		RecordInManAccounting = True;
		PostInAccounting = True;
		RecordInTA = False;
	EndIf;
	
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;

	Documents.IntangibleAssetsInitialRecognition2_4.FillInCost(ThisObject);
	
EndProcedure

Procedure FillInBasedOnInventory(Val FillingData)
	
	DocumentBasis = Undefined;
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	GeneratedDocument = True;
	
	Organization = Catalogs.Companies.EmptyRef();
	Department = Catalogs.BusinessStructure.EmptyRef();
	
	BusinessOperation = Enums.BusinessTransactions.IntangibleAssetsInitialRecognitionByInventoryCount;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.IntangibleAssetsInitialRecognition2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers); 
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
