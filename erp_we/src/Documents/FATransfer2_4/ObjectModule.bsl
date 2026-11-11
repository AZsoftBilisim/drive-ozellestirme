#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	FATransferLocalization.Filling(ThisObject, FillingData, StandardProcessing);

	ItemsAndDimensionsSelectionParameters = Documents.FATransfer2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	
	If BusinessOperation = Enums.BusinessTransactions.FATransfer Then
		NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferSubAssets Then
		NonCurrentAssetsInternal.CheckThatNodesAreSelected(ThisObject, "FA", "FixedAsset", Cancel);
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	ItemDetailsParameters = Documents.FATransfer2_4.PropertyValuesOfDependentProps(
		ThisObject, Documents.FATransfer2_4.ThereAreOwnFA(ThisObject));
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	If BusinessOperation = Enums.BusinessTransactions.FATransfer
		And ValueIsFilled(ReceivingBusinessUnit)
		And Department = ReceivingBusinessUnit
		And ValueIsFilled(InventoryCustodianRecipient)
		And FinanciallyLiablePerson = InventoryCustodianRecipient
		And Not ValueIsFilled(RecipientLocationAddress) Then
		
		MessageText = NStr("vi = 'Người nhận phải khác với người gửi ';
							|ru = 'МОЛ-получатель должен отличаться от МОЛ-отправителя';
							|en = 'Responsible employee as recipient must be different from responsible employee as sender'; fa = 'Responsible employee as recipient must be different from responsible employee as sender';
							|it = 'Persona responsabile finanziarmente - destinario deve essere diversa dalla persona responsabile finanziarmente- mittente';
							|pl = 'Osoba odpowiedzialna materialnie - odbiorca musi różnić się od Osoby odpowiedzialnej materialnie - nadawcy';
							|tr = 'Alıcı MOL, gönderenin MOL''ünden farklı olmalıdır'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "InventoryCustodianRecipient", "", Cancel);
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.FATransfer
		And ValueIsFilled(ReceivingBusinessUnit)
		And Department = ReceivingBusinessUnit
		And Not ValueIsFilled(FinanciallyLiablePerson) 
		And Not ValueIsFilled(InventoryCustodianRecipient)
		And Not ValueIsFilled(RecipientLocationAddress) Then
		
		MessageText = NStr("vi = 'Bạn phải chọn một đơn vị đích khác với đơn vị gửi';
							|ru = 'Необходимо выбрать подразделение-получатель отличное от подразделения-отправителя';
							|en = 'Select a receiving department different from the shipping department'; fa = 'Select a receiving department different from the shipping department';
							|it = 'È necessario selezionare il reparto-destinatario diverso dal reparto-mittente';
							|pl = 'Musisz wybrać dział odbiorczy inny niż dział wysyłający.';
							|tr = 'Gönderen kuruluş departmanından farklı bir ikincil kuruluş depaermanı seçmeniz gerekir'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "ReceivingBusinessUnit", "", Cancel);
		
	EndIf; 
	
	ItemsAndDimensionsSelectionParameters = Documents.FATransfer2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	FATransferLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	GeneratedDocument = False;
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	FATransferLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ClearUnusedProps();
	
	If WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		NonCurrentAssetsInternal.FillInReflectionInAccounting(ThisObject, FA.Unload().UnloadColumn("FixedAsset"));
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.FATransfer
		Or BusinessOperation = Enums.BusinessTransactions.TransferSubAssets Then
		CompanyRecipient = Organization;
	EndIf;
	
	If Not ValueIsFilled(RecipientLocationAddress) Then
		RecipientLocationAddress = "";
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	FATransferLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	ItemsAndDimensionsSelectionParameters = Documents.FATransfer2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	FATransferLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	FATransferLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	FATransferLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure BlockReadableData()

	// It is necessary to block the data that is used when recording movements.
	// For example, data registers of information that are used to fill in missing resources.
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialFixedAssetsInformation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	LockItem = Block.Add("InformationRegister.FALocation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = FA;
	LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
	
	If RecordInManAccounting Then
		
		LockItem = Block.Add("InformationRegister.FixedAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf;
	
	If RecordInLocalAccounting Then
		
		LockItem = Block.Add("InformationRegister.AccountingProcedureForOSBU");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = FA;
		LockItem.UseFromDataSource("FixedAsset", "FixedAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf;
	
	Block.Lock(); 
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	
	ElsIf Basis.Property("DocumentBasis")
		And TypeOf(Basis.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		
		FillInBasedOnInventory(Basis);
	
	EndIf;
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder, Description");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể điều chuyển trên cơ sở nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Перемещение на основании группы ОС невозможно.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot transfer based on fixed assets group. Select fixed assets.
			|To expand the group, press Ctrl+Down.'; fa = 'Cannot transfer based on fixed assets group. Select fixed assets.
			|To expand the group, press Ctrl+Down.';
			|it = 'Trasferimento in base al gruppo Capitali Fissi non è possibile.
			|Selezionate il capitale fisso. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przeniesienie na podstawie grupy ST nie jest możliwe.
			| Wybierz ST. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałki w dół.';
			|tr = 'Bir sabit kıymet grubuna dayalı bir transfer oluşturmak mümkün değildir. 
			| Bir sabit kıymet seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	FALocation = NonCurrentAssets.FALocation(Basis);
	FillPropertyValues(ThisObject, FALocation);
	Department = FALocation.FixedAssetsLocation;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;
	
EndProcedure

Procedure FillInBasedOnInventory(FillingData)
	
	BusinessOperation = Enums.BusinessTransactions.FATransfer;
	
	GeneratedDocument = True;
	
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.FATransfer2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure ClearUnusedProps()

	ItemDetailsParameters = Documents.FATransfer2_4.PropertyValuesOfDependentProps(
		ThisObject, Documents.FATransfer2_4.ThereAreOwnFA(ThisObject));
		
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA");
	
EndProcedure

#EndRegion

#EndIf
