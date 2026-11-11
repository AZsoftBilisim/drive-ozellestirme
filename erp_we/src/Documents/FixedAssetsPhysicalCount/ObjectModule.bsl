#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentAttributes_FixedAssetPhysicalInventory(ThisObject);
	TMCommonUseClientServer.ClearUnusedProps(ThisObject, ItemDetailsParameters);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
	For Each RowData In FA Do
		
		RowData.CostByAccountingDataLA = 0;
		RowData.AvailabilityByAccountingData = False;
		
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If BusinessOperation = Enums.BusinessTransactions.PhysicalCountOfConstructionInProgress
		And NonCurrentAssets.VNAManagementIsUsed_2_4(Date) Then
		MessageTemplate = NStr("vi = 'Đối tượng xây dựng ""%1"" đã được chọn trong dòng %2.';
								|ru = 'Объект строительства ""%1"" уже выбран в строке %2.';
								|en = 'Construction site ""%1"" is already selected in line %2.'; fa = 'Construction site ""%1"" is already selected in line %2.';
								|it = 'Construction site ""%1"" is already selected in line %2.';
								|pl = 'Construction site ""%1"" is already selected in line %2.';
								|tr = '""%1"" inşaat nesnesi %2  satırında zaten seçilmiş.'");
	Else
		MessageTemplate = NStr("vi = 'Tài sản cố định ""%1"" đã được chọn trên dòng  %2.';
								|ru = 'Основное средство ""%1"" уже выбрано в строке %2.';
								|en = 'Asset ""%1"" is already selected in line %2.'; fa = 'Asset ""%1"" is already selected in line %2.';
								|it = 'Capitale fisso ""%1"" già selezionato nella riga %2.';
								|pl = 'Środek trwały ""%1"" jest już wybrany w wierszu %2.';
								|tr = 'Sabit kıymet ""%1''''%2satırında zaten seçili .'");
	EndIf; 
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "AccountingObject", Cancel, MessageTemplate);
	
	If PhysicalInventoryCountCommission.Count() <> 0 
		And PhysicalInventoryCountCommission.Find(True, "Chairman") = Undefined Then
		
		MessageText = NStr("vi = 'Cần chọn chủ tịch ủy ban';
							|ru = 'Необходимо выбрать председателя комиссии';
							|en = 'Select the commission chairperson'; fa = 'Select the commission chairperson';
							|it = 'Select the commission chairperson';
							|pl = 'Select the commission chairperson';
							|tr = 'Komisyon başkanının seçilmesi gerekir'");
		Common.MessageToUser(MessageText, ThisObject, "PhysicalInventoryCountCommission",, Cancel); 
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
EndProcedure

#EndRegion

#EndIf
