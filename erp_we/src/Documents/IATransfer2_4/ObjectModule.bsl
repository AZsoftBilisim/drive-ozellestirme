#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") Then
		FillInBasedOnIntangibleAsset(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.IntangibleAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	IATransferLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__IA(ThisObject);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	If BusinessOperation = Enums.BusinessTransactions.IATransfer
		And ValueIsFilled(ReceivingBusinessUnit)
		And Department = ReceivingBusinessUnit Then
		MessageText = NStr("vi = 'Bạn phải chọn một đơn vị đích khác với đơn vị gửi';
							|ru = 'Необходимо выбрать подразделение-получатель отличное от подразделения-отправителя';
							|en = 'Select a receiving business unit different from the shipping business unit'; fa = 'Select a receiving business unit different from the shipping business unit';
							|it = 'È necessario selezionare il reparto-destinatario diverso dal reparto-mittente';
							|pl = 'Musisz wybrać dział odbiorczy inny niż dział wysyłający.';
							|tr = 'Gönderen kuruluş departmanından farklı bir ikincil kuruluş depaermanı seçmeniz gerekir'");
		CommonClientServer.MessageToUser(MessageText, ThisObject, "ReceivingBusinessUnit", "", Cancel);
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	IATransferLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
	IATransferLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ClearUnusedProps();

	If WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatIAAreAcceptedForAccounting(ThisObject, Cancel);
		NonCurrentAssetsInternal.FillInReflectionInAccounting(ThisObject, IA.Unload().UnloadColumn("IntangibleAsset"));
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "IA");
	
	PropertyValuesOfDependentProps =
		NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__IA(ThisObject);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, PropertyValuesOfDependentProps);
	
	If BusinessOperation = Enums.BusinessTransactions.IATransfer Then
		CompanyRecipient = Organization;
	EndIf;
	
	IATransferLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	IATransferLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockData_();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IATransferLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IATransferLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure BlockData_()
	
	Block = New DataLock;
	
	LockItem = Block.Add("InformationRegister.InitialIntangibleAssetsInformation");
	LockItem.Mode = DataLockMode.Shared;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsAccountingProcedure");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	LockItem.SetValue("Organization", Organization);
	
	LockItem = Block.Add("InformationRegister.IntangibleAssetsRegistrationPlace");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = IA;
	LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
	
	If RecordInLocalAccounting Then
		
		LockItem = Block.Add("InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
		
	EndIf;
	
	If RecordInManAccounting Then
		LockItem = Block.Add("InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IA;
		LockItem.UseFromDataSource("IntangibleAsset", "IntangibleAsset");
		LockItem.SetValue("Organization", Organization);
	EndIf;
	
	Block.Lock();
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

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
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể điều chuyển trên cơ sở nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Перемещение на основании группы НМА невозможно.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot transfer based on intangible assets group. 
			|Select intangible assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot transfer based on intangible assets group. 
			|Select intangible assets. To expand the group, press Ctrl+Down.';
			|it = 'Trasferimento in base al gruppo Beni Immateriali non è possibile.
			|Selezionate il bene immateriale. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przeniesienie na podstawie grupy WNM nie jest możliwa.
			| Wybierz WNM. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałki w dół.';
			|tr = 'Maddi olmayan varlık grubuna dayalı bir transfer oluşturmak mümkün değildir. 
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl ve aşağı ok tuşlarını kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(Basis);
	FillPropertyValues(ThisObject, IntangibleAssetsRegistrationPlace);
	
	LineOfATabularSection = IA.Add();
	LineOfATabularSection.IntangibleAsset = Basis;
	
EndProcedure

Procedure FillInBasedOnInventory(FillingData)
	
	GeneratedDocument = True;
	
	Organization = Catalogs.Companies.EmptyRef();
	Department = Catalogs.BusinessStructure.EmptyRef();
	
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.IATransfer2_4.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

Procedure ClearUnusedProps()

	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__IA(ThisObject);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "IA");
	
EndProcedure

#EndRegion

#EndIf
