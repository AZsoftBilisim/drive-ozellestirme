// @strict-types


#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If Patch Then
		DocumentCorrection.CheckFillingOfStorno(ThisObject, Cancel, CheckedAttributes)
	Else
		AttributesNotToCheck.Add("CorrectionNumber");
		AttributesNotToCheck.Add("CorrectionDate");
		AttributesNotToCheck.Add("ReversedDocument");
		AttributesNotToCheck.Add("CorrectedDocument");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	VATAmount = VATAccrual.Total("VATAmount");
	TMCommonUse.FillInDocumentIDs(ThisObject, "VATAccrual");
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not Patch Then
		CorrectionNumber = "";
		CorrectionDate  = '00010101';
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	ArrayOfTypesToFillInFromRegistry = New Array;
	ArrayOfTypesToFillInFromRegistry.Add(Type("DocumentRef.VendorInvoice"));
	ArrayOfTypesToFillInFromRegistry.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	ArrayOfTypesToFillInFromRegistry.Add(Type("DocumentRef.SubcontractorReport2_5"));
	ArrayOfTypesToFillInFromRegistry.Add(Type("DocumentRef.RedemptionOfGoodsFromStorage"));
	ArrayOfTypesToFillInFromRegistry.Add(Type("DocumentRef.PurchaseAdjustment"));
	
	If Not ArrayOfTypesToFillInFromRegistry.Find(FillInDataType) = Undefined Then
		
		DocumentBasis = FillingData;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	DocumentsRegistry.Organization AS Organization,
		|	DocumentRegistryKeys.Key AS Counterparty,
		|	DocumentsRegistry.Partner AS Partner,
		|	DocumentsRegistry.Department AS Department
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		LEFT JOIN Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
		|		ON (DocumentsRegistry.Counterparty = DocumentRegistryKeys.Ref)
		|WHERE
		|	DocumentsRegistry.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(SUM(DocumentAmountsInAccountingCurrencySliceLast.AmountExcludingVATCompl), 0) AS AmountExcludingVATCompl
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency.SliceLast(
		|			&Period,
		|			Recorder = &Ref
		|				AND PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)) AS DocumentAmountsInAccountingCurrencySliceLast";
		
		Query.SetParameter("Ref", FillingData);
		Query.SetParameter("Period", CurrentSessionDate());
		
		QueryPackage = Query.ExecuteBatch();
		HeaderSelection = QueryPackage[0].Select();
		If HeaderSelection.Next() Then
			
			FillPropertyValues(ThisObject, HeaderSelection);
			
		EndIf;
		
		If Not QueryPackage[1].IsEmpty() Then
			
			VATAccrual.Clear();
			
		EndIf;
		
		AmountsSelection = QueryPackage[1].Select();
		If AmountsSelection.Next() Then
			
			TaxBase = AmountsSelection.AmountExcludingVATCompl;
			VATRate = VATAccountingERP.DefaultVATRate(Organization, Date);
			If ValueIsFilled(VATRate) Then
				
				VATRateByNumber = Common.ObjectAttributeValue(VATRate, "Rate1");
				
			Else
				
				VATRateByNumber = 0;
				
			EndIf;
			
			NewLineCalculationOfVAT = VATAccrual.Add();
			NewLineCalculationOfVAT.TaxBase = TaxBase;
			NewLineCalculationOfVAT.VATRate = VATRate;
			NewLineCalculationOfVAT.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(TaxBase, VATRateByNumber, False);
			
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.ReverseVATAccrual") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	TMCommonUse.ClearDocumentIDs(ThisObject, "VATAccrual");
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	VATAmount = VATAccrual.Total("VATAmount");
	
EndProcedure

#EndRegion

#EndIf
