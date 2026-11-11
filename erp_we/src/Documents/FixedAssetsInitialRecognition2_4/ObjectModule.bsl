
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut(FillingData);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.ConstructionObjects") Then
		FillInBasedOnConstructionObject(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.LeaseContract") Then
		FillInBasedOnLeaseAgreement(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
		FillInBasedOnAcceptanceForAccounting(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SigningOfLeaseContract") Then
		FillInBasedOnConclusionOfLeaseAgreement(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.LeaseTermAdjustment") Then
		FillInOnBasisOfRentalTermsADJUSTMENTChanges(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	FixedAssetsInitialRecognitionLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Comment = "";
	DocumentBasis = Undefined;
	GeneratedDocument = False;
	DocumentInAnotherAccounting = Undefined;
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	FixedAssetsInitialRecognitionLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);

	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = 
		NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckHeaderDetails_(Cancel);
	CheckFixedAssets(AuxiliaryAttributes, Cancel);
	CheckDetailsAndExpenses(ItemDetailsParameters, CheckedAttributes, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	FixedAssetsInitialRecognitionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, AuxiliaryAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		BlockData_();
		NonCurrentAssetsInternal.CheckPossibilityOfTakingIntoAccountFA(ThisObject, Cancel);
		CheckAcceptanceForAccountingUnderLeaseAgreement(Cancel);
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	FixedAssetsInitialRecognitionLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	FixedAssetsInitialRecognitionLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	FixedAssetsInitialRecognitionLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	FixedAssetsInitialRecognitionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(FinancialAccountingGroup) Then
		FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(Enums.KindsOfNonCurrentAssets.FixedAsset);
	EndIf; 
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	VATTaxation = NonCurrentAssets.VATTaxation(Organization, Date);
	
	NonCurrentAssetsClientServer.WhenChangingBankingDetails_AcceptanceForAccountingByFA(
		ThisObject, 
		AuxiliaryAttributes(), 
		"Organization,RecordInManAccounting,RecordInLocalAccounting");
	
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

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("Date") Then
		Date = Basis.Date;
	EndIf;
	
	If Basis.Property("Organization")
		And ValueIsFilled(Basis.Organization) Then
		
		Organization = Basis.Organization;
	EndIf;

	If Basis.Property("FixedAsset") Then
		
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	
	ElsIf Basis.Property("ConstructionObject") Then
		
		FillInBasedOnConstructionObject(Basis.ConstructionObject);
	
	ElsIf Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		
		FillInBasedOnInventory(Basis);
	
	EndIf; 
	
	If Basis.Property("AdjustmentModeFromPreviousDate") Then
		
		AdjustmentModeFromPreviousDate = True;
		
		If Basis.Property("CorrectionDate") Then
			If Basis.CorrectionDate < ?(Date <> '00010101', Date, CurrentSessionDate()) Then
				DateOfRecognition = Basis.CorrectionDate;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Basis.Property("RecordInManAccounting")
		Or Basis.Property("PostInAccounting")
		Or Basis.Property("RecordInTA") Then
		
		RecordInManAccounting = Basis.RecordInManAccounting;
		PostInAccounting = Basis.PostInAccounting;
		
		
		RecordInLocalAccounting = PostInAccounting Or RecordInTA;
		
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(FixedAsset)
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	If TypeOf(FixedAsset) = Type("Array") Then
		
		ListOfFA = New Array;

		For Each Item In FixedAsset Do
			If ValueIsFilled(Item) Then
				ListOfFA.Add(Item);
			EndIf;
		EndDo;
		
	Else
		
		ListOfFA = CommonClientServer.ValueInArray(FixedAsset);
		
	EndIf;
	
	NonCurrentAssetsInternal.CheckCreationOfDocumentBasedOnFAGroup(ListOfFA);
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	If TypeOf(FixedAsset) <> Type("Array") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FixedAsset, "IsFolder");
		
		If DetailsOfFoundation.IsFolder Then
			
			MessageText = NStr("vi = 'Không thể tiếp nhận vào kế toán TSCĐ trên cơ sở nhóm TSCĐ.
				|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
				|ru = 'Принятие к учету ОС на основании группы ОС невозможен.
				|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
				|en = 'Cannot recognize fixed assets based on fixed assets group.
				|Select fixed assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot recognize fixed assets based on fixed assets group.
				|Select fixed assets. To expand the group, press Ctrl+Down.';
				|it = 'Registrazione nella contabilità del capitale fisso in base al gruppo Capitali fissi non è possibile. 
				|Selezionate il capitale fisso. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
				|pl = 'Przyjęcie do ewidencji środków trwałych na podstawie grupy środków trwałych jest niemożliwe.
				|Wybierz środki trwałe. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
				|tr = 'Sabit kıymet grupları bazında sabit kıymetler - ilk tahakkuk işlemi mümkün değildir.
				| Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
			Raise(MessageText);
			
		EndIf;
		
		ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
		
		InitialInformation = Catalogs.Assets.InitialInformation(FixedAsset, Date);
		If ValueIsFilled(InitialInformation.CommissioningDocumentAC) 
			And (Not ValueIsFilled(InitialInformation.CommissioningDocumentTA)
					And ComplianceCAAccountingIsKept
				Or Not ValueIsFilled(InitialInformation.CommissioningDocumentMA))
			And (TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.FixedAssetsInitialRecognition2_4")
				Or TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4")
				Or TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.OBEntrySubAssetsAndComponentsOfDepreciation")) Then
	
			If TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
				FillInBasedOnAcceptanceForAccounting(InitialInformation.CommissioningDocumentAC, FixedAsset);
			Else
				FillBasedOnEnteringBalances(InitialInformation.CommissioningDocumentAC, FixedAsset);
			EndIf;
		
			Return;
			
		ElsIf ValueIsFilled(InitialInformation.CommissioningDocumentTA) 
			And (Not ValueIsFilled(InitialInformation.CommissioningDocumentAC)
				Or Not ValueIsFilled(InitialInformation.CommissioningDocumentMA))
			And (TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.FixedAssetsInitialRecognition2_4")
				Or TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4")
				Or TypeOf(InitialInformation.CommissioningDocumentAC) = Type("DocumentRef.OBEntrySubAssetsAndComponentsOfDepreciation")) Then
				
			If TypeOf(InitialInformation.CommissioningDocumentTA) = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
				FillInBasedOnAcceptanceForAccounting(InitialInformation.CommissioningDocumentTA, FixedAsset);
			Else
				FillBasedOnEnteringBalances(InitialInformation.CommissioningDocumentTA, FixedAsset);
			EndIf;
			
			Return;
			
		ElsIf ValueIsFilled(InitialInformation.CommissioningDocumentMA) 
			And (Not ValueIsFilled(InitialInformation.CommissioningDocumentAC)
				Or Not ValueIsFilled(InitialInformation.CommissioningDocumentTA)
					And ComplianceCAAccountingIsKept)
			And (TypeOf(InitialInformation.CommissioningDocumentMA) = Type("DocumentRef.FixedAssetsInitialRecognition2_4")
				Or TypeOf(InitialInformation.CommissioningDocumentMA) = Type("DocumentRef.EntryOfCapitalAssetsBalance2_4")
				Or TypeOf(InitialInformation.CommissioningDocumentMA) = Type("DocumentRef.OBEntrySubAssetsAndComponentsOfDepreciation")) Then
				
			If TypeOf(InitialInformation.CommissioningDocumentMA) = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
				FillInBasedOnAcceptanceForAccounting(InitialInformation.CommissioningDocumentMA, FixedAsset);
			Else
				FillBasedOnEnteringBalances(InitialInformation.CommissioningDocumentMA, FixedAsset);
			EndIf;
			
			Return;
			
		ElsIf InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.Recognized_
					And InitialInformation.BUState = Enums.FixedAssetsStates.Recognized_
					And InitialInformation.StateTa = Enums.FixedAssetsStates.Recognized_
				Or InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
				Or InitialInformation.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
				Or InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.Recognized_
					And InitialInformation.BUState = Enums.FixedAssetsStates.Recognized_
					And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
			
			MessageText = StrTemplate(NStr("vi = 'Tài sản cố định ""%1"" đã được tính.';
											|ru = 'Основное средство ""%1"" уже принято к учету.';
											|en = 'The ""%1"" fixed asset is already recognized.'; fa = 'The ""%1"" fixed asset is already recognized.';
											|it = 'Il capitale fisso ""%1"" è già stato registrato nella contabilità.';
											|pl = 'Środki trwałe ""%1"" są już przyjęte do ewidencji';
											|tr = 'Sabit kıymet ""%1"" zaten dikkate alınmıştır.'"), String(FixedAsset));
			Raise MessageText;
			
		EndIf; 
	EndIf;
	
	For Each Item In ListOfFA Do
		LineOfATabularSection = FA.Add();
		LineOfATabularSection.FixedAsset = Item;
	EndDo;
	
	Documents.FixedAssetsInitialRecognition2_4.FillInCost(ThisObject);
	
	FillInBasedOnGroupOS();
	
	FixedAssetsInitialRecognitionLocalization.FillInBasedOnObjectOfOperation(ThisObject, FixedAsset);
	
EndProcedure

Procedure FillInBasedOnConstructionObject(ConstructionObjectBase)

	If Not ValueIsFilled(ConstructionObjectBase) Then
		Return;
	EndIf;
	
	If Common.ObjectAttributeValue(ConstructionObjectBase, "IsFolder") Then
		
		MessageText = NStr("vi = 'Không thể tiếp nhận vào kế toán TSCĐ trên cơ sở nhóm đối tượng xây dựng.
			|Hãy chọn đối tượng xây dựng. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống';
			|ru = 'Принятие к учету ОС на основании группы объектов строительства невозможен.
			|Выберите объект строительства. Для раскрытия группы используйте клавиши Ctrl и стрелку внизю';
			|en = 'Cannot recognize fixed assets based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down'; fa = 'Cannot recognize fixed assets based on assets under construction group.
			|Select an asset under construction. To expand the group, press Ctrl+Down';
			|it = 'Registrazione nella contabilità del capitale fisso in base al gruppo degli oggetti in costruzione non è possibile. 
			|Selezionate l''oggetto in costruzione. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù';
			|pl = 'Przyjęcie do ewidencji środków trwałych na podstawie grupy obiektów budowy jest niemożliwe.
			|Wybierz obiekt budowy. Aby rozwinąć grupę użyj klawiszy Ctrl oraz strzałkę w dól.';
			|tr = 'Bir grup yapı nesnesi bazında sabit kıymet - ilk tahakkuk işlemi mümkün değildir. 
			|Bir yapı nesnesi seçin. Grubu genişletmek için Ctrl tuşunu ve aşağı oku kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	DimensionKindExpenseCapitalization = Enums.KindsOfExpenseCapitalizationDimension.ConstructionObject;
	ConstructionObject = ConstructionObjectBase;
	
EndProcedure

Procedure FillInBasedOnAcceptanceForAccounting(Basis, FixedAsset = Undefined)

	BaseObject = Basis.GetObject(); // DocumentObject.FixedAssetsInitialRecognition2_4
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	
	DocumentInAnotherAccounting = Basis;
	
	If Not ValueIsFilled(FixedAsset) Then
		For Each BaseString In BaseObject.FA Do
			LineOfATabularSection = FA.Add();
			LineOfATabularSection.FixedAsset = BaseString.FixedAsset;
		EndDo; 
		FA.Load(BaseObject.FA.Unload());
	Else
		LineOfATabularSection = FA.Add();
		LineOfATabularSection.FixedAsset = FixedAsset;
	EndIf; 
	
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
	
	Documents.FixedAssetsInitialRecognition2_4.FillInCost(ThisObject);
	
	FixedAssetsInitialRecognitionLocalization.FillInBasedOnAcceptanceForAccountingOrEnteringBalances(ThisObject, Basis);
	
	ClearUnusedProps();
	
EndProcedure

Procedure FillBasedOnEnteringBalances(Basis, FixedAsset)

	BaseObject = Basis.GetObject(); // DocumentObject.EntryOfCapitalAssetsBalance2_4
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted,BusinessOperation");
	
	FAString = BaseObject.FA.Find(FixedAsset, "FixedAsset");
	If FAString <> Undefined Then
		FillPropertyValues(ThisObject, FAString);
	EndIf;
	
	DocumentInAnotherAccounting = Basis;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = FixedAsset;
	
	If NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		
		If BaseObject.RecordInLocalAccounting 
			And Not BaseObject.RecordInManAccounting Then
			RecordInLocalAccounting = False;
			PostInAccounting = False;
			RecordInTA = False;
			RecordInManAccounting  = True;
		Else
			RecordInLocalAccounting = True;
			PostInAccounting = True;
			RecordInTA = True;
			RecordInManAccounting  = False;
		EndIf;
		 
	Else	
		RecordInLocalAccounting = True;
		RecordInManAccounting  = True;
		PostInAccounting = True;
		RecordInTA = False;
	EndIf;
	
	Documents.FixedAssetsInitialRecognition2_4.FillInCost(ThisObject);
	
	FixedAssetsInitialRecognitionLocalization.FillInBasedOnAcceptanceForAccountingOrEnteringBalances(ThisObject, Basis);
	
	ClearUnusedProps();
	
EndProcedure

Procedure FillInBasedOnLeaseAgreement(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TermsOfLeaseContracts.Recorder AS Recorder
	|FROM
	|	InformationRegister.TermsOfLeaseContracts.SliceFirst(, Contract = &Basis) AS TermsOfLeaseContracts
	|WHERE
	|	TermsOfLeaseContracts.Recorder REFS Document.SigningOfLeaseContract";
	
	Query = New Query(QueryText);
	Query.SetParameter("Basis", Basis);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		MessageText = NStr("vi = 'Chưa ký kết hợp đồng, nên không thể tiếp nhận vào kế toán';
							|ru = 'Не оформлено заключение договора, принятие к учету недоступно';
							|en = 'The contract signing has not been registered, recognition is not available'; fa = 'The contract signing has not been registered, recognition is not available';
							|it = 'Conclusione del contratto non registrata, impossibile registrare in contabilità';
							|pl = 'Nie utworzono zawarcia umowy, przyjęcie do ewidencji jest niedostępne';
							|tr = 'Sözleşmenin imzalanması resmileştirilmemiştir, kayıt için kabul mevcut değildir'");
		Raise(MessageText);
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	FillInBasedOnConclusionOfLeaseAgreement(Selection.Recorder);
	
EndProcedure

Procedure FillInBasedOnConclusionOfLeaseAgreement(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;

	ErrorText = Documents.FixedAssetsInitialRecognition2_4.FillInBasedOnConclusionOfLeaseAgreement(ThisObject, Basis);
	
	If ErrorText <> Undefined Then
		Raise ErrorText;
	EndIf;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(
									ThisObject, AuxiliaryAttributes());
	
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA,TargetFinancing");
	
EndProcedure

Procedure FillInOnBasisOfRentalTermsADJUSTMENTChanges(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;

	ErrorText = Documents.FixedAssetsInitialRecognition2_4.FillInOnBasisOfRentalTermsADJUSTMENTChanges(ThisObject, Basis);
	
	If ErrorText <> Undefined Then
		Raise ErrorText;
	EndIf;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(
									ThisObject, AuxiliaryAttributes());
	
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA,TargetFinancing");
	
EndProcedure

Procedure FillInBasedOnInventory(FillingData)
	
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	
	DocumentBasis = Undefined;
	GeneratedDocument = True;
	
	BusinessOperation = Enums.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.FixedAssetsInitialRecognition2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure FillInBasedOnGroupOS()
	
	ListOfFA = New Array;
	For Each RowData In FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf; 
	EndDo; 
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf; 

	QueryText = 
	"SELECT
	|	Lots.Ref AS Ref
	|INTO Lots
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS Lots
	|WHERE
	|	Lots.FixedAsset IN (&ListOfFA)
	|	AND Lots.OperationCategory.AccountAsGroupFA
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	InventoryInOperation.Lot.OperationCategory.ServiceLife AS ServiceLife,
	|	InventoryInOperation.Lot.OperationCategory.ExpenseItem AS ExpenseItem
	|FROM
	|	AccumulationRegister.InventoryInOperation.Balance(
	|		&Date, 
	|		Lot IN
	|			(SELECT
	|				T.Ref
	|			FROM
	|				Lots AS T)) AS InventoryInOperation";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	
	If Selection.Next() Then
		
		If RecordInManAccounting Then
			UsefulLifeManagementAccounting = Selection.ServiceLife;
			ExpenseItemManagementAccounting = Selection.ExpenseItem;
		EndIf;
		
		If PostInAccounting Then
			UsefulLifeAccounting = Selection.ServiceLife;
			ExpenseItemAccounting = Selection.ExpenseItem;
		EndIf;
		
		FixedAssetsInitialRecognitionLocalization.FillInBasedOnGroupOS(ThisObject, Selection.ExpenseItem);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckHeaderDetails_(Cancel)

	FixedAssetsInitialRecognitionLocalization.CheckHeaderDetails_(ThisObject, Cancel);

	CheckRegistrationDate(Cancel);
	CheckOrderDoNotTakeIntoAccountIncludeInExpenses(Cancel);
	
	NonCurrentAssetsInternal.CheckFACostGenerationProcedure(ThisObject, Cancel);
	
EndProcedure

Procedure CheckFixedAssets(AuxiliaryAttributes, Cancel)

	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckDetailsOfFAWhenTakingIntoAccount(ThisObject, "FA", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);

	If AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
		TemplateResidualValueAC = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị theo kế toán doanh nghiệp';
										|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости по бух. учету';
										|en = 'Residual value in line %1 must be less than the cost in local accounting'; fa = 'Residual value in line %1 must be less than the cost in local accounting';
										|it = 'Residual value in line %1 must be less than the cost in local accounting';
										|pl = 'Residual value in line %1 must be less than the cost in local accounting';
										|tr = '%1 satırındaki artık değer muhasebe değerinden küçük olmalıdır.'");
		TemplateResidualValueMA = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị cho ex. kế toán';
										|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости по упр. учету';
										|en = 'Residual value in line %1 must be less than the cost in mgmt accounting'; fa = 'Residual value in line %1 must be less than the cost in mgmt accounting';
										|it = 'Il costo di liquidazione nella riga %1 deve essere minore del costo secondo la contabilità gestionale';
										|pl = 'Wartość likwidacyjna w wierszu %1 powinna być mniejsza niż wartość według ewidencji administracyjnej';
										|tr = '%1 satırındaki artık değer yönetim muhasebesi değerinden küçük olmalıdır.'");
	Else
		TemplateResidualValueAC = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị theo tiền tệ kế toán tài chính';
										|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости в валюте регл. учета';
										|en = 'Residual value in line %1 must be less than the cost in the local accounting currency'; fa = 'Residual value in line %1 must be less than the cost in the local accounting currency';
										|it = 'Residual value in line %1 must be less than the cost in the local accounting currency';
										|pl = 'Residual value in line %1 must be less than the cost in the local accounting currency';
										|tr = '%1 satırındaki tasfiye değeri yasal muhasebesi para biriminden küçük olmalıdır.'");
		TemplateResidualValueMA = NStr("vi = 'Giá trị thanh lýtrong dòng %1 phải nhỏ hơn giá trị trong loại tiền kiểm soát. kế toán';
										|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости в валюте упр. учета';
										|en = 'Residual value in line %1 must be less than the cost in the currency of mgmt accounting'; fa = 'Residual value in line %1 must be less than the cost in the currency of mgmt accounting';
										|it = 'Il costo di liquidazione nella riga %1 deve essere minore del costo in valuta della contabilità gestionale';
										|pl = 'Wartość likwidacyjna w wierszu %1 musi być mniejsza niż wartość w walucie zarz. ewidencji';
										|tr = '%1 satırındaki artık değer yönetim muhasebesi para biriminden küçük olmalıdır.'");
	EndIf; 
	
	For Each RowData In FA Do
		
		LineNumber = Format(RowData.LineNumber, "NG=");
		
		If RowData.ResidualValueLocal >= RowData.CostInAccounting 
			And RowData.CostInAccounting <> 0
			And PostInAccounting Then
			
			MessageText = StrTemplate(TemplateResidualValueAC, LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "ResidualValueLocal");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If RowData.ResidualValueMan >= RowData.CostInManagementAccounting 
			And RowData.CostInManagementAccounting <> 0
			And RecordInManAccounting
			And (AuxiliaryAttributes.FALocalAccountingIsConductedIndependently
				Or AuxiliaryAttributes.CurrencyOfMan <> AuxiliaryAttributes.ComplCurrency) Then
			
			MessageText = StrTemplate(TemplateResidualValueMA, LineNumber);
			Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "ResidualValueMan");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure CheckDetailsAndExpenses(ItemDetailsParameters, CheckedAttributes, Cancel)

	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsInitialRecognition2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemAccounting", AccountingProcedureAC, "ACC", Cancel);
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemTaxAccounting", AccountingProcedureTA, "TA", Cancel);
	NonCurrentAssets.CheckArticleInOrderOfAccounting(ThisObject, "ExpenseItemManagementAccounting", AccountingProcedureMA, "MA", Cancel);
	
EndProcedure

Procedure CheckAcceptanceForAccountingUnderLeaseAgreement(Cancel)

	If BusinessOperation <> Enums.BusinessTransactions.RecognitionOfLeaseItems Then
		Return;
	EndIf;
	
	// Documents created by the end of the year are used to switch to FSB 25 and should fall into the inter-reporting period.
	If Not AccountingPoliciesTaxSettingsLocalization.FSB25IsApplied(Organization, Date) 
		 And AccountingPoliciesTaxSettingsLocalization.FSB25IsApplied(Organization, Date + 1) Then
		Return;
	EndIf;
	
	// The date of acceptance for accounting must be later than the date of conclusion of the lease Contract.
	ListOfFA = New Array;
	For Each RowData In FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	MAX(LeasedAsset.Period) AS Date
	|FROM
	|	InformationRegister.LeasedAsset AS LeasedAsset
	|WHERE
	|	LeasedAsset.FixedAsset IN(&ListOfFA)
	|	AND LeasedAsset.Contract = &Contract
	|	AND LeasedAsset.Period >= &Date
	|	AND LeasedAsset.Active
	|
	|	AND LeasedAsset.State = VALUE(Enum.FixedAssetsStates.LeaseContractsSigned)
	|
	|	AND (LeasedAsset.Recorder REFS Document.SigningOfLeaseContract
	|		OR LeasedAsset.Recorder REFS Document.LeaseTermAdjustment)
	|
	|HAVING
	|	ISNULL(MAX(LeasedAsset.Period), DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Assets.Ref AS Ref,
	|	Assets.Presentation AS Presentation
	|FROM
	|	Catalog.Assets AS Assets
	|
	|WHERE
	|	Assets.Ref IN (&ListOfFA)
	|	AND NOT Assets.Ref IN (
	|		SELECT
	|			LeasedAsset.FixedAsset
	|		FROM
	|			InformationRegister.LeasedAsset.SliceLast(&Date, Recorder <> &Ref AND FixedAsset IN (&ListOfFA)) AS LeasedAsset
	|		WHERE
	|			LeasedAsset.State IN (
	|				VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
	|				VALUE(Enum.FixedAssetsStates.InLease))
	|			AND (LeasedAsset.Contract = &Contract 
	|				OR &Contract = VALUE(Catalog.LeaseContract.EmptyRef)))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()-1].Select();
	If Selection.Next() Then
		MessageText = NStr("vi = 'Ngày tiếp nhận vào kế toán phải muộn hơn ngày ký hợp đồng thuê %1';
							|ru = 'Дата принятия к учету должна быть позже даты заключения договора аренды %1';
							|en = 'The recognition date must be later than the rental contract signing date %1'; fa = 'The recognition date must be later than the rental contract signing date %1';
							|it = 'La data di ricezione in contabilità deve essere successiva alla data di conclusione del contratto di affitto%1';
							|pl = 'Data przyjęcia do ewidencji musi być późniejsza niż data zawarcia umowy dzierżawy %1';
							|tr = 'Muhasebeleştirme tarihi %1 kiralama tarihinden sonra olmalıdır'");
		MessageText = StrTemplate(MessageText, Selection.Date);
		Common.MessageToUser(MessageText, ThisObject, "Date",, Cancel); 
	EndIf;	
	
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		RowData = FA.Find(Selection.Ref, "FixedAsset");
		MessageText = NStr("vi = 'Đối với tài sản cố định ""%1"" chưa lập kết luận hợp đồng thuê.';
							|ru = 'Для основного средства ""%1"" не оформлено заключение договора аренды.';
							|en = 'The rental term commitment is not registered for the ""%1"" fixed asset.'; fa = 'The rental term commitment is not registered for the ""%1"" fixed asset.';
							|it = 'The rental term commitment is not registered for the ""%1"" fixed asset.';
							|pl = 'The rental term commitment is not registered for the ""%1"" fixed asset.';
							|tr = '""%1"" sabit kıymeti için kira sözleşmesi akdi oluşturulmamış.'");
		MessageText = StrTemplate(MessageText, Selection.Presentation);
		Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
		Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
	EndDo;	

	FixedAssetsInitialRecognitionLocalization.CheckAcceptanceForAccountingUnderLeaseAgreementBeforeWrite(ThisObject, Cancel);
		
EndProcedure

Procedure CheckRegistrationDate(Cancel)
	
	If Not AdjustmentModeFromPreviousDate
		Or Not ValueIsFilled(DateOfRecognition) Then
		Return
	EndIf;
	
	If DateOfRecognition >= BegOfMonth(Date)
		And ValueIsFilled(Date) Then
		MessageText = NStr("vi = 'Ngày tiếp nhận vào kế toán phải sớm hơn ngày đầu tháng lập chứng từ';
							|ru = 'Дата принятия к учету должна быть раньше начала месяца, в котором оформлен документ';
							|en = 'The recognition date must be earlier than the beginning of the month in which the document is created'; fa = 'The recognition date must be earlier than the beginning of the month in which the document is created';
							|it = 'La data di ricezione in contabilità deve essere precedente all''inizio del mese nel quale è registrato il documento';
							|pl = 'Data przyjęcia do ewidencji powinna być wcześniej niż początek miesiąca, w którym został zarejestrowany dokument';
							|tr = 'Kayıt için kabul tarihi, belgenin düzenlendiği ayın başından önce olmalıdır'");
		Common.MessageToUser(MessageText, ThisObject, "DateOfRecognition",, Cancel);
	ElsIf Not NonCurrentAssets.VNAManagementIsUsed_2_4(DateOfRecognition) Then
		MessageText = NStr("vi = 'Ngày tiếp nhận vào kế toán không được sớm hơn ngày bắt đầu ghi nhận tài sản dài hạn phiên bản 2.4';
							|ru = 'Дата принятия к учету должна быть не раньше начала учета внеоборотных активов версии 2.4';
							|en = 'The recognition date must not be earlier than the start of fixed and intangible assets accounting version 2.4'; fa = 'The recognition date must not be earlier than the start of fixed and intangible assets accounting version 2.4';
							|it = 'La data di ricezione in contabilità non deve essere precedente all''inizio della contabilità degli attivi non correnti della versione 2.4';
							|pl = 'Data przyjęcia do ewidencji powinna być nie wcześniej niż początek ewidencji aktywów nieobrotowych wersji 2.4';
							|tr = 'Muhasebe için kabul tarihi, duran varlıklar için muhasebeleştirme başlangıcından daha erken olmamalıdır sürüm 2.4'");
		Common.MessageToUser(MessageText, ThisObject, "DateOfRecognition",, Cancel);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.RecognitionOfLeaseItems Then
		MessageText = NStr("vi = 'Không hỗ trợ tiếp nhận vào kế toán theo hợp đồng thuê từ ngày trước đó';
							|ru = 'Принятие к учету по договору аренды с прошлой даты не поддерживается';
							|en = 'Recognition under the rental contract from the previous date is not supported'; fa = 'Recognition under the rental contract from the previous date is not supported';
							|it = 'La ricezione in contabilità per accordo di affitto dalla data precedente non è supportata';
							|pl = 'Przyjęcie do ewidencji zgodnie z umową dzierżawy z ubiegłą datą nie jest obsługiwane';
							|tr = 'Önceki tarihten itibaren bir kira sözleşmesi kapsamında dikkate alınması desteklenmez'");
		Common.MessageToUser(MessageText, ThisObject, "AdjustmentModeFromPreviousDate",, Cancel);
	EndIf;
	
EndProcedure 

Procedure CheckOrderDoNotTakeIntoAccountIncludeInExpenses(Cancel)
	
	CheckCompleted = FixedAssetsInitialRecognitionLocalization.CheckOrderDoNotTakeIntoAccountIncludeInExpenses(ThisObject, Cancel);
	If CheckCompleted Then
		Return;
	EndIf;
	
	If (AccountingProcedureMA = Enums.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses
			Or Not RecordInManAccounting)
		And (AccountingProcedureAC = Enums.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses
			Or Not PostInAccounting) 
		And (RecordInManAccounting
			Or PostInAccounting) Then
		
		If PostInAccounting Then
			Field = "AccountingProcedureAC";
		Else
			Field = "AccountingProcedureMA";
		EndIf;
		
		MessageText = NStr("vi = 'Không hỗ trợ chọn trình tự kế toán ""Không tiếp nhận vào kế toán, đưa vào chi phí"" ngay trong tất cả các dạng kế toán. Một trong số các dạng kế toán cần có trình tự kế toán khác.';
							|ru = 'Не поддерживается выбор порядка учета ""Не принимать к учету, включить в расходы"" сразу во всех учетах. В одном из учетов должен быть другой порядок учета.';
							|en = 'Cannot select the ""Do not recognize, add to expenses"" accounting procedure in all accountings at the same time. One of the accountings must have a different accounting procedure.'; fa = 'Cannot select the ""Do not recognize, add to expenses"" accounting procedure in all accountings at the same time. One of the accountings must have a different accounting procedure.';
							|it = 'Не поддерживается выбор порядка учета ""Не принимать к учету, включить в расходы"" сразу во всех учетах. В одном из учетов должен быть другой порядок учета.';
							|pl = 'Cannot select the ""Do not recognize, add to expenses"" accounting procedure in all accountings at the same time. One of the accountings must have a different accounting procedure.';
							|tr = '""Kayda alma, giderlere dahil et"" muhasebe sırası seçimi tüm hesaplarda aynı anda desteklenmez. Hesaplardan biri farklı bir muhasebe sırasına sahip olmalıdır.'");
		Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure BlockData_()

	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.LeasedAsset");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	FALocalAccountingIsConductedIndependently = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
		Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())));
	
	For Each RowData In FA Do
		
		If Not FALocalAccountingIsConductedIndependently
			And CurrencyOfMan = ComplCurrency Then
		
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
			
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_AcceptanceForAccountingByFA(ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA,TargetFinancing");

EndProcedure

Function AuxiliaryAttributes()
	
	DateOfParameters = EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()));
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Date));
	AuxiliaryAttributes.Insert("UseConstructionObjects", GetFunctionalOption("UseConstructionObjects"));
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInAccounting", PostInAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", RecordInTA);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("IncomeTaxPayer", False);
	AuxiliaryAttributes.Insert("STSIsAppliedIncomeMinusExpenses", False);
	AuxiliaryAttributes.Insert("SettingUpReflectionOfTaxExpensesIsRequired", False);
	AuxiliaryAttributes.Insert("PropertyTaxAdvancesArePaid", False);
	AuxiliaryAttributes.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	AuxiliaryAttributes.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", AuxiliaryAttributes.CurrencyOfMan = AuxiliaryAttributes.ComplCurrency);
	AuxiliaryAttributes.Insert("ThereAreRelatedCompanies", Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization));
	
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

	FixedAssetsInitialRecognitionLocalization.AddAuxiliaryDetails(ThisObject, AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
