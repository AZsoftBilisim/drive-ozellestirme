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
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "OtherExpenses");
	
	OBEntryLocalization.OBEntryOtherExpensesBeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOtherExpensesProcessing(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	OBEntryLocalization.EnteringBalancesOtherExpensesProcessingDeletions(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not RecordInOperationalAccounting 
		And Not PostInCostAccounting
		And Not PostInFinancialAndTaxAccounting
		And Not RecordInMA Then
		
		MessageText = NStr("vi = 'Hoạt động phải được phản ánh trong một trong các tài khoản';
							|ru = 'Операция должна отражаться в одном из учетов';
							|en = 'The operation must be recorded in one of accounting types'; fa = 'The operation must be recorded in one of accounting types';
							|it = 'L''operazione deve essere riportata in uno dei tipi della contabilità';
							|pl = 'Operacja powinna być odzwierciedlana w jednej z ewidencji';
							|tr = 'İşlemin hesaplardan birine yansıtılması gerekir'");
		Common.MessageToUser(MessageText, , 
			"Object.RecordInOperationalAccounting", , Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryOfOtherExpenses Then
		For Each String In OtherExpenses Do
			If String.Sum = 0 And String.AmountExcludingVAT = 0 And String.SumCompl = 0 
			 And String.VATLocal = 0 And String.AmountTemporaryDifferences = 0 And String.AmountPermanentDifferences = 0 Then
				ErrorText = NStr("vi = 'Số tiền không được chỉ định trong dòng %LineNumber% của phần bảng';
								|ru = 'Не указаны суммы в строке %LineNumber% табличной части';
								|en = 'Amounts in row %LineNumber% of the table are not specified'; fa = 'Amounts in row %LineNumber% of the table are not specified';
								|it = 'Nessun importo indicato nella riga %LineNumber% della parte tabulare';
								|pl = 'Nie wskazano wartości w wierszu %LineNumber% części tabelarycznej';
								|tr = 'Tablo bölümünün %LineNumber% satırındaki tutarlar belirtilmedi'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", String.LineNumber);
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("OtherExpenses", String.LineNumber, "LineNumber"),
					,
					Cancel);
			EndIf;
		EndDo;
	EndIf;
	
	NotCheckedAttributeArray.Add("VATActivityType");
	
	If (Not RecordInOperationalAccounting And Not PostInCostAccounting) Then
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	If Not RecordInOperationalAccounting  Then
		NotCheckedAttributeArray.Add("OtherExpenses.Sum");
		NotCheckedAttributeArray.Add("OtherExpenses.VATRate");
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OBEntryLocalization.EnteringBalancesOtherExpensesProcessingFillChecks(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	OBEntryLocalization.EnteringBalancesOtherExpensesProcessingFilling(ThisObject, FillingData, StandardProcessing);
	
	FillParameters = Documents.OBEntryOtherExpenses.InitializeParametersForVATActivities(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	TMCommonUse.ClearDocumentIDs(ThisObject, "OtherExpenses");
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	LocalAccountingCurrency       = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ManagementAccountingCurrency           = Constants.ManagementAccountingCurrency.Get();
	FactorOfConversionFromManCurrencyToRegulCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		ManagementAccountingCurrency,
		LocalAccountingCurrency,
		?(Date = Date(1,1,1), CurrentSessionDate(), Date));
	
	StructureOfRecalculationOfAmount     = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	LocalSumRecalculationStructure = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	LocalSumRecalculationStructure.PriceIncludesVAT = False;

	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;

	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(OtherExpenses, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", LocalSumRecalculationStructure);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		OtherExpenses,
		Undefined);
	
	OBEntryLocalization.EnteringBalancesOtherCopyingCosts(ThisObject, CopiedObject);
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OBEntryLocalization.EnteringBalancesOtherRecordingCosts(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.ManagementAccountingCurrency();
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
	
	FillParameters = Documents.OBEntryOtherExpenses.InitializeParametersForVATActivities(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
