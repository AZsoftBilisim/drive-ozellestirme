#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFillingItOut();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
		
		FillInBasedOnInventory(FillingData);
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.Decomissioning.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.Decomissioning));

	ItemsAndDimensionsSelectionParameters = Documents.Decomissioning.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	CheckingDocumentFilling(AttributesNotToCheck, Cancel);
	CheckingFillingOfOtherSubsystems(CheckedAttributes, AttributesNotToCheck, Cancel);
	
	DecomissioningLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocumentBeforeFillingItOut(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);

	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure FillInSelectionDocument(FillingData)
	
	If FillingData.Property("Goods") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		EndIf;
		
		For Each CollectionItem In FillingData.Goods Do
			RowData = Goods.Add();
			FillPropertyValues(RowData, CollectionItem);
		EndDo;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.Decomissioning);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	ElsIf FillingData.Property("DocumentBasis")
		And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
			
		FillInBasedOnInventory(FillingData);
		
	EndIf;
	
EndProcedure

Procedure FillInBasedOnInventory(Val FillingData)
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
		ArrayOfLineNumbers = Undefined;
		ReportErrors = True;
	EndIf;
	
	ActionCompleted = Documents.Decomissioning.FillInBasedOnInventory(ThisObject, ArrayOfLineNumbers);
	
	If Not ActionCompleted And ReportErrors Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %1 không có các dòng cần ghi giảm';
						|ru = 'В документе %1 отсутствуют строки требующие списания';
						|en = 'There are no lines that require write-off in the %1 document'; fa = 'There are no lines that require write-off in the %1 document';
						|it = 'Nel documento %1 mancano le righe che richiedono lo storno';
						|pl = 'W dokumencie %1 brak wierszy wymagających rozchodu';
						|tr = '%1Belgesinde gider yazılması gereken satır yok'");
		ErrorText = StrTemplate(ErrorText, DocumentBasis);
		Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckingDocumentFilling(AttributesNotToCheck, Cancel)
	
	InventoryInOperationServer.CheckInventoryRecords(ThisObject, AttributesNotToCheck, Cancel);
	InventoryInOperationServer.CheckAccountingForIndividuals(ThisObject, AttributesNotToCheck, Cancel);
	
EndProcedure

Procedure CheckingFillingOfOtherSubsystems(CheckedAttributes, AttributesNotToCheck, Cancel)
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, AttributesNotToCheck, Cancel);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.Decomissioning),
		Cancel,
		AttributesNotToCheck);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf