#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
		
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OBEntryLocalization.OBEntryOtherAssetsAndLiabilitiesBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesProcessing(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesProcessingOfDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not RecordInOperationalAccounting Then
		
		MessageText = NStr("vi = 'Hoạt động phải được phản ánh trong một trong số các tài khoản';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not RecordInOperationalAccounting Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	NotCheckedAttributeArray.Add("Department");
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesProcessingFillChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.InputOfBalancesOfOtherAssetsLiabilitiesProcessingOfFilling(ThisObject, FillingData, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherAssetsAndLiabilities.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesWhenCopying(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OBEntryLocalization.EnteringBalancesOfOtherAssetsLiabilitiesWhenRecording(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(ThisObject, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
