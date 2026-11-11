#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		Date		= FillingData.Date;
		Organization = FillingData.Organization;
		If FillingData.Property("MonthEndClosingMode") Then
			MonthEndClosingMode = FillingData.MonthEndClosingMode;
		EndIf;
		
		// It is only possible to upgrade the status of an existing document: Preliminary -> Actual.
		// When performing some stages of the closing of the month (distribution of production costs)
		// , it is possible to recalculate the preliminary cost price according to a document with the "Actual calculation" sign.
		// At the same time, only the movements according to the registers of information are corrected,
		// the remaining movements will remain from the calculation of the actual cost.
		If IsNew() Or PreliminaryCalculation Then
			PreliminaryCalculation = FillingData.PreliminaryCalculation;
		EndIf;
		
		// The evaluation method is only needed for the actual calculation
		EvaluationMethod = ?(PreliminaryCalculation, Undefined, FillingData.EvaluationMethod);
		
		// Duplicate the organization in the tabular part for backward compatibility
		Companies.Clear();
		Companies.Add().Organization = Organization;
		
	EndIf;
	
	InventoryCostCalculationLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;

	If Companies.Count() = 0 And Not ValueIsFilled(Organization) Then

		ErrorText = NStr("vi = 'Chưa chỉ ra doanh nghiệp để tính toán giá vốn';
						|ru = 'Не указана организация для расчета себестоимости';
						|en = 'Company for calculating cost is required.'; fa = 'Company for calculating cost is required.';
						|it = 'La società per il calcolo del costo di produzione non è indicata';
						|pl = 'Nie podano firm do kalkulacji kosztów własnych';
						|tr = 'Maliyet hesaplaması için herhangi bir iş yeri belirtilmedi'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"Companies",
			, // DataPath 
			Cancel);

		Return;

	EndIf;

	If PreliminaryCalculation Then
		NotCheckedAttributeArray.Add("EvaluationMethod");
	EndIf;

	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);

	InventoryCostCalculationLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If ValueIsFilled(Organization) Then
		If Companies.Count() <> 1 Or Companies[0].Organization <> Organization Then
			// Duplicate the organization in the tabular part for backward compatibility
			Companies.Clear();
			Companies.Add().Organization = Organization;
		EndIf;
	EndIf;
	
	NewPresentationOfOrganizations = CostCalculationAppliedAlgorithms.CalculatedCompanies(Companies.UnloadColumn("Organization"), ", ", True);
	If CalculatedCompanies <> NewPresentationOfOrganizations Then
		CalculatedCompanies = NewPresentationOfOrganizations;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	
	InventoryCostCalculationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	InventoryCostCalculationLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InventoryCostCalculationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#EndIf
