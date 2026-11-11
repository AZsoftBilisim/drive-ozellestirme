#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ClearUnusedProps();

	If Not Cancel And WriteMode = DocumentWriteMode.Posting Then
		LeasedAssetAccountingInternal.CheckThatFAHasNotBeenLeasedForBalance(ThisObject, Cancel);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
		
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesOfDependentProps_ReceiptOfLeasedFA(ThisObject, AuxiliaryAttributes);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	BlockReadableData();
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReceiveLeasedAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
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
	
	Block.Lock(); 
	
EndProcedure

Procedure ClearUnusedProps()
	
	AuxiliaryAttributes = AuxiliaryAttributes();
	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentProps_ReceiptOfLeasedFA(
		ThisObject, AuxiliaryAttributes);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters, "FA");

EndProcedure

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("CAAccounting24IsUsed", NonCurrentAssets.VNAManagementIsUsed_2_4(Date));
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndIf



