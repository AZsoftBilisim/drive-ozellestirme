#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		BlockData_();
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		NonCurrentAssetsInternal.CheckPossibilityOfTakingIntoAccountFA(ThisObject, Cancel);
		NonCurrentAssetsInternal.CheckThatFAIsNotReceivedForRentOnBalance(ThisObject, Cancel);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
		
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
	
	FillInBankingDetailsBeforeWrite();
	
	ItemsAndDimensionsSelectionParameters = Documents.SplitFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SplitFixedAssetsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode); 
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	SplitFixedAssetsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	SplitFixedAssetsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SplitFixedAssets") Then
		FillOnBasisOfDisassembly(FillingData);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.SplitFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SplitFixedAssetsLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("FA.CostInManagementAccounting");
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
		NonCurrentAssetsInternal.CheckThatComponentNodesAreSelected(ThisObject, "FA", "FixedAsset", Cancel);
	Else
		NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
	EndIf;
		
	AuxiliaryAttributes = Documents.SplitFixedAssets.AuxiliaryAttributes(ThisObject);	
	
	CheckDocument(AuxiliaryAttributes, CheckedAttributes, NotCheckedAttributeArray, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.SplitFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	SplitFixedAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	SplitFixedAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	SplitFixedAssetsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể ngừng hoạt động đối với nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Разукомплектация группы ОС невозможна.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot split fixed assets group.
			| Select a single fixed assets. To expand the group, press Ctrl+Down arrow.'; fa = 'Cannot split fixed assets group.
			| Select a single fixed assets. To expand the group, press Ctrl+Down arrow.';
			|it = 'Non è possibile effettuare il decompletamento del gruppo di Capitale Fisso. 
			|Selezionate il capitale fisso. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Zdekompletowanie grupy ST nie jest możliwe. 
			|Wybierz ST. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałki w dół.';
			|tr = 'Sabit kıymet gruplarını iptal edemezsiniz. 
			|Sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(Basis, Date);
	
	Organization = InitialInformation.Organization;
	Department = InitialInformation.FixedAssetsLocation;
	
	FixedAsset = Basis;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
	RecordInLocalAccounting = 
		ValueIsFilled(InitialInformation.CommissioningDocumentAC)
		Or ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	
EndProcedure

Procedure FillOnBasisOfDisassembly(Basis, FixedAsset = Undefined)

	BaseObject = Basis.GetObject();
	
	FillPropertyValues(ThisObject, BaseObject,, "Number,Date,DataVersion,EmployeeResponsible,DeletionMark,Posted");
	
	DocumentInAnotherAccounting = Basis;
	
	If Not ValueIsFilled(FixedAsset) Then
		FixedAsset = BaseObject.FixedAsset;
	EndIf; 
	
	
	If NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		If BaseObject.RecordInLocalAccounting Then
			RecordInLocalAccounting = False;
			RecordInManAccounting  = True;
		Else
			RecordInLocalAccounting = True;
			RecordInManAccounting  = False;
		EndIf; 
	Else	
		RecordInLocalAccounting = True;
		RecordInManAccounting  = True;
	EndIf;
	
	FA.Load(BaseObject.FA.Unload());
	
	If Constants.ManagementAccountingCurrency.Get() = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization) Then
		
		For Each RowData In FA Do
			If RecordInLocalAccounting Then
				RowData.CostInAccounting = RowData.CostInManagementAccounting;
				RowData.CostInTaxAccounting = RowData.CostInManagementAccounting;
			ElsIf RecordInManAccounting Then
				RowData.CostInManagementAccounting = ?(RowData.CostInAccounting <> 0, RowData.CostInAccounting, RowData.CostInTaxAccounting);
			EndIf; 
		EndDo; 
		
	EndIf; 
	
	ClearUnusedProps();
	
EndProcedure

#EndRegion

#Region Other

Procedure BlockData_()

	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	Block.Lock(); 
	
EndProcedure

Procedure CheckDocument(AuxiliaryAttributes, CheckedAttributes, NotCheckedAttributeArray, Cancel)
	
	CheckTableOfFixedAssets(AuxiliaryAttributes, CheckedAttributes, NotCheckedAttributeArray, Cancel);
	
	If Not RecordInLocalAccounting And Not RecordInManAccounting Then
		MessageText = NStr("vi = 'Cần phản ánh chứng từ vào một trong các dạng kế toán';
							|ru = 'Документ должен отражаться в одном из учетов';
							|en = 'The document must be recorded in one of accounting types'; fa = 'The document must be recorded in one of accounting types';
							|it = 'Il documento deve essere riportato in una delle contabilità';
							|pl = 'Dokument powinien być odzwierciedlany w jednej z ewidencji';
							|tr = 'Belge, kayıtlarının birinde yansıtılmalıdır'");
		Common.MessageToUser(MessageText,, "Object.RecordInLocalAccounting",, Cancel);
	EndIf;
	
EndProcedure

Procedure CheckTableOfFixedAssets(AuxiliaryAttributes, CheckedAttributes, NotCheckedAttributeArray, Cancel)

	NonCurrentAssetsInternal.CheckDetailsOfFAWhenTakingIntoAccount(ThisObject, "FA", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHasNotBeenTransferredToFinLease(ThisObject, Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets
		And FA.Count() = 1 Then
		
		MessageText = NStr("vi = 'Để tháo dỡ, cần phải chọn một số tài sản cố định.';
							|ru = 'Для разукомплектации необходимо выбрать несколько основных средств.';
							|en = 'To perform splitting, several fixed assets should be selected.'; fa = 'To perform splitting, several fixed assets should be selected.';
							|it = 'Per lo smantellamento è necessario seleziona alcuni capitali fissi.';
							|pl = 'Dla zdekompletowania należy wybrać kilka środków trwałych.';
							|tr = 'Sökme için, birkaç sabit kıymet seçmeniz gerekir.'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "FA",, Cancel);
	EndIf;
	
	If ValueIsFilled(FixedAsset) Then
		
		RowData = FA.Find(FixedAsset, "FixedAsset");
		If RowData <> Undefined Then
			
			MessageText = NStr("vi = 'Tài sản chính đã được tính đến';
								|ru = 'Основное средство уже принято к учету';
								|en = 'The fixed asset is already recognized'; fa = 'The fixed asset is already recognized';
								|it = 'L''oggetto di capitale fisso è stato già registrato in contabilità.';
								|pl = 'Środek trwały został już przyjęty do ewidencji';
								|tr = 'Sabit kıymet zaten dikkate alınmıştır'");
			Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf; 
		
		// Checking the group of operating systems and the direction of activity of the operating systems being taken into account.
		ListOfFA = FA.UnloadColumn("FixedAsset");
		CheckResult = Documents.SplitFixedAssets.CheckSelectionOfFixedAssets(FixedAsset, ListOfFA, Date);
		If CheckResult.ProblematicFA.Count() <> 0 Then
			
			MessageTemplate = SplitFixedAssetsLocalization.FACheckMessageTemplate(CheckResult);
			
			If MessageTemplate <> Undefined Then
			
				For Each RowData In FA Do
					If CheckResult.ProblematicFA.Find(RowData.FixedAsset) <> Undefined Then
						MessageText = StrTemplate(MessageTemplate, String(RowData.FixedAsset));
						Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
						CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
					EndIf;
				EndDo;
			
			EndIf;
			 
		EndIf;
		
	EndIf; 
	
	// Checking the filling of the tabular part
	
	MessageTemplateCostLocal = NStr("vi = 'Đối với tài sản cố định ""%1"", bạn phải chỉ định giá trị bằng đơn vị tiền tệ của regl.';
									|ru = 'Для основного средства ""%1"" необходимо указать стоимость в валюте регл.';
									|en = 'Specify cost in the currency of local for the ""%1"" fixed asset'; fa = 'Specify cost in the currency of local for the ""%1"" fixed asset';
									|it = 'Per l''oggetto del capitale fisso ""%1"" è necessario indicare il costo in valuta della contabilità di regolamentazione.';
									|pl = 'W przypadku środka trwałego „%1” należy określić wartość w reg. walucie';
									|tr = '""%1"" sabit kıymeti için, düzenlenmiş muhasebe para birimindeki değer belirtilmelidir'");
	
	If Not AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
		MessageTemplateCostOfMan = NStr("vi = 'Đối với tài sản cố định ""%1"", chi phí phải được chỉ định bằng loại tiền kiểm soát.';
										|ru = 'Для основного средства ""%1"" необходимо указать стоимость в валюте упр.';
										|en = 'Specify cost in mgmt accounting for the ""%1"" fixed asset'; fa = 'Specify cost in mgmt accounting for the ""%1"" fixed asset';
										|it = 'Per l''oggetto del capitale fisso ""%1"" è necessario indicare il costo in valuta della contabilità gestionale.';
										|pl = 'W przypadku środka trwałego „%1” należy określić wartość w zarz. walucie';
										|tr = 'Sabit kıymet ""%1"" için, yönetim muhasebesi para birimindeki maliyet belirtilmelidir'");
	Else
		MessageTemplateCostOfMan = NStr("vi = 'Đối với tài sản cố định ""%1"", bạn phải chỉ định chi phí trong kế toán quản trị';
										|ru = 'Для основного средства ""%1"" необходимо указать стоимость в управленческом учете';
										|en = 'Specify cost in management accounting for the ""%1"" fixed asset'; fa = 'Specify cost in management accounting for the ""%1"" fixed asset';
										|it = 'Per l''oggetto del capitale fisso ""%1"" è necessario indicare il costo nella contabilità gestionale';
										|pl = 'Środek trwały ""%1"" powinien mieć podaną wartość w ewidencji zarządczej';
										|tr = '""%1"" sabit kıymeti için, yönetim muhasebesindeki maliyet belirtilmelidir'");
	EndIf;
			
	MessageTemplateLiquidationValue = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị cho kế toán quản trị';
											|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости по упр. учету';
											|en = 'Residual value in line %1 must be less than the cost in mgmt accounting'; fa = 'Residual value in line %1 must be less than the cost in mgmt accounting';
											|it = 'Il costo di liquidazione nella riga %1 deve essere minore del costo secondo la contabilità gestionale';
											|pl = 'Wartość likwidacyjna w wierszu %1 powinna być mniejsza niż wartość według ewidencji administracyjnej';
											|tr = '%1 satırındaki artık değer yönetim muhasebesi değerinden küçük olmalıdır.'");
	MessageTemplateLiquidationValueLocal = NStr("vi = 'Giá trị thanh lý trong dòng %1 phải nhỏ hơn giá trị cho thông thường. kế toán';
												|ru = 'Ликвидационная стоимость в строке %1 должна быть меньше стоимости по регл. учету';
												|en = 'Residual value in line %1 must be less than the cost in local accounting'; fa = 'Residual value in line %1 must be less than the cost in local accounting';
												|it = 'Il costo di liquidazione nella riga %1 deve essere minore del costo secondo la contabilità di regolamentazione';
												|pl = 'Wartość likwidacyjna w wierszu%1 powinna być niższa niż koszt reg. ewidencji';
												|tr = '%1 satırındaki artık değer yerel muhasebe değerinden küçük olmalıdır.'");
	
	PathToProps = "FA.";
	VerifiableTSDetails = New Array;
	VerifiableDetailsWithoutTSName = New Array;
	For Each NameOfPropsToCheck In CheckedAttributes Do
		If StrStartsWith(NameOfPropsToCheck, PathToProps) Then
			VerifiableTSDetails.Add(NameOfPropsToCheck);
			VerifiableDetailsWithoutTSName.Add(StrSplit(NameOfPropsToCheck, ".")[1]);
		EndIf; 
	EndDo; 

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiableTSDetails);

	ObjectMetadata = Metadata();
	PresentationOfDetails = Undefined;
	MessageTemplate = NStr("vi = 'Trong thông tin về tài sản cố định ""%1"", chưa điền trường %2.';
							|ru = 'В сведениях об основном средстве ""%1"" не заполнено поле %2.';
							|en = 'Field %2 in the %1 fixed asset data is not filled in.'; fa = 'Field %2 in the %1 fixed asset data is not filled in.';
							|it = 'Nei dati dell''immobilizzazione materiale ""%1"" non è stato compilato il campo %2.';
							|pl = 'W danych o środku trwałym ""%1"" nie wypełniono pola %2.';
							|tr = 'Sabit kıymet ""%1"" ayrıntılarında, %2alan doldurulmadı.'");
	For Each RowData In FA Do
		
		ItemDetailsParameters = 
			NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FADisassembly(RowData, AuxiliaryAttributes);
		TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
		
		For Each AttributeName In VerifiableDetailsWithoutTSName Do
			
			If NotCheckedAttributeArray.Find(AttributeName) <> Undefined Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(RowData[AttributeName]) Then
				
				AttributeRepresentation = NonCurrentAssetsInternal.AttributeRepresentation(
											AttributeName, "FA", PresentationOfDetails, ObjectMetadata);
											
				// When editing in a separate window, the message must be linked to the line number
				// so that when the message is selected, the editing form does not open.
				MessageText = StrTemplate(MessageTemplate, 
											RowData["FixedAsset"], 
											AttributeRepresentation);
											
				Field = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "LineNumber");
				
				Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
				
				// Used to get fill check errors from the calling code.
				NonCurrentAssetsInternal.AddFillInCheckResult(
					ThisObject,
					AttributeRepresentation,
					"FA",
					RowData.LineNumber,
					RowData["FixedAsset"]);
				
			EndIf;
			
		EndDo; 
		
		SplitFixedAssetsLocalization.CheckTSString(RowData, ThisObject, AuxiliaryAttributes, Cancel);
		
	EndDo; 
	
EndProcedure

Procedure FillInBankingDetailsBeforeWrite()

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);

	ClearUnusedProps();
	
	If RecordInManAccounting And RecordInLocalAccounting Then
		DocumentInAnotherAccounting = Undefined;
	EndIf;
		
	For Each RowData In FA Do

		If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())))
			And CurrencyOfMan = ComplCurrency Then
			RowData.CostInManagementAccounting = RowData.CostInAccounting;
		EndIf; 

		If CurrencyOfMan = ComplCurrency Then
			RowData.ResidualValueMan = RowData.ResidualValueLocal;
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = Documents.SplitFixedAssets.AuxiliaryAttributes(ThisObject);
	
	For Each RowData In FA Do
		
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FADisassembly(RowData, AuxiliaryAttributes);
		TMCommonUseClientServer.ClearUnusedProps(RowData, ItemDetailsParameters);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
