#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private 

#Region Print

// Create printed forms of objects
//
// Parameters:
// 		ObjectsArray - Array - Array of links to the objects to be printed
// 		PrintParameters - Structure - Structure of additional printing parameters
// 		PrintFormsCollection - ValueTable - Generated tabular documents
// 		PrintObjects - Print Objects
// 		OutputParameters - Structure - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReferenceCalculationOfAccrualOfInterest") Then
		
		SpreadsheetDocument = GeneratePrintedFormOfCalculationReference(ObjectsArray, PrintObjects, PrintParameters);
		SpreadsheetDocument.PrintParametersKey = "PRINTPARAMETER_SPRACTION_ACCOUNTSPERCENTAGES";
		
		TemplateSynonym = NStr("vi = 'Bảng tính lãi theo TSCĐ đã chuyển cho thuê';
								|ru = 'Справка-расчет начисления процентов по переданным в аренду ОС';
								|en = 'Sheet of charged interest on leased fixed assets'; fa = 'Sheet of charged interest on leased fixed assets';
								|it = 'Справка-расчет начисления процентов по переданным в аренду ОС';
								|pl = 'Sheet of charged interest on leased fixed assets';
								|tr = 'Belge-kiralanan sabit kıymetlere ilişkin faiz tahakkuk hesaplaması'");
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReferenceCalculationOfAccrualOfInterest",
			TemplateSynonym,
			SpreadsheetDocument);
		
	EndIf;
	
EndProcedure

Function GeneratePrintedFormOfCalculationReference(Document, PrintObjects, PrintParameters)

	SetPrivilegedMode(True);
	
	DocumentData = GetCalculationHelpData(Document, PrintParameters.DataForPrint);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PageOrientation  = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "PRINTPARAMETER_SPRACTION_ACCOUNTSPERCENTAGES";
	SpreadsheetDocument.ReadOnly = True;
	
	Template = DataProcessors.PrintSheetOfChargedInterestOnLeasedFixedAssets.GetTemplate("PF_MXL_ReferenceCalculationOfAccrualOfInterest");
	
	HelpHeaderArea = Template.GetArea("Header_Help");
	SelectionByDocuments = DocumentData.Select(QueryResultIteration.ByGroups);
	
	While SelectionByDocuments.Next() Do

		PrintData = New Structure("Date, Number, Presentation");
		FillPropertyValues(PrintData, SelectionByDocuments);
		HelpHeaderArea.Parameters.Document = TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData);

		SpreadsheetDocument.Put(HelpHeaderArea);

		FAHeaderArea  = Template.GetArea("Header_FA");
		FAStringAreaIs = Template.GetArea("String_OS");
		AreaOfTotalFA  = Template.GetArea("Total_FA");

		SelectionByFA = SelectionByDocuments.Select(QueryResultIteration.ByGroups);

		While SelectionByFA.Next() Do
			FAHeaderArea.Parameters.Fill(SelectionByFA);
			SpreadsheetDocument.Put(FAHeaderArea);
			TotalDaysOfDebt = 0;

			SelectionByDate = SelectionByFA.Select();
			
			// We will calculate the amount of the remaining debt and the number of days of debt during the withdrawal process.
			ThisIsFirstLineOfFA = True;
			While SelectionByDate.Next() Do

				If ThisIsFirstLineOfFA Then
					DebtAmountWithoutVAT = SelectionByDate.PresentValue + SelectionByDate.NGLV;
					PreviousDate = BegOfDay(Document.Date);
					ThisIsFirstLineOfFA = False;
				EndIf;

				DaysOfDebt = (SelectionByDate.ScheduleDate - PreviousDate) / 86400;
				TotalDaysOfDebt = TotalDaysOfDebt + DaysOfDebt;
				PreviousDate = SelectionByDate.ScheduleDate;

				FAStringAreaIs.Parameters.Fill(SelectionByDate);
				FAStringAreaIs.Parameters.DaysOfDebt = DaysOfDebt;
				FAStringAreaIs.Parameters.DebtAmountWithoutVAT = DebtAmountWithoutVAT;

				SpreadsheetDocument.Put(FAStringAreaIs);

				DebtAmountWithoutVAT = Max(DebtAmountWithoutVAT - SelectionByDate.PaymentAmountWithoutVAT + SelectionByDate.Interests,
					0);

			EndDo;

			AreaOfTotalFA.Parameters.Fill(SelectionByFA);
			AreaOfTotalFA.Parameters.TotalDaysOfDebt = TotalDaysOfDebt;
			SpreadsheetDocument.Put(AreaOfTotalFA);
		EndDo;

	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetCalculationHelpData(Document, DataForPrint) 

	// Convert an array of additional data structures from a document form to a table of values.
	DescriptionOfRateOfReturn  = New TypeDescription("Number", New NumberQualifiers(15,4,AllowedSign.Nonnegative));
	DescriptionOfAmounts = New TypeDescription("Number", New NumberQualifiers(30,2,AllowedSign.Nonnegative)); 
	
	AdditionalDataTable_ = New ValueTable;
	AdditionalDataTable_.Columns.Add("FixedAsset", New TypeDescription("CatalogRef.Assets"));
	AdditionalDataTable_.Columns.Add("RateOfReturn", DescriptionOfRateOfReturn);
	AdditionalDataTable_.Columns.Add("AdvancePayments", DescriptionOfAmounts);
	AdditionalDataTable_.Columns.Add("PresentValue", DescriptionOfAmounts);
	AdditionalDataTable_.Columns.Add("NGLV", DescriptionOfAmounts);
	
	For Each FAString In DataForPrint Do
		StringOfYieldRates = AdditionalDataTable_.Add();
		FillPropertyValues(StringOfYieldRates, FAString);
	EndDo;
	
	Query = New Query;
	Query.SetParameter("AdditionalDataTable_", AdditionalDataTable_);
	Query.SetParameter("Document", Document);
	
	QueryText = 
	"SELECT
	|	AdditionalDataTable_.FixedAsset AS FixedAsset,
	|	AdditionalDataTable_.RateOfReturn AS RateOfReturn,
	|	AdditionalDataTable_.AdvancePayments AS AdvancePayments,
	|	AdditionalDataTable_.PresentValue AS PresentValue,
	|	AdditionalDataTable_.NGLV AS NGLV
	|INTO TT_AdditionalData
	|FROM
	|	&AdditionalDataTable_ AS AdditionalDataTable_
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProvideAssetsToLeasee2_4.Ref AS Ref,
	|	ProvideAssetsToLeasee2_4.Organization AS Organization,
	|	ProvideAssetsToLeasee2_4.Leaseholder AS Counterparty,
	|	ProvideAssetsToLeasee2_4.Contract AS Contract,
	|	ProvideAssetsToLeasee2_4.Contract.VATRate AS VATRate,
	|	ProvideAssetsToLeasee2_4.Contract.ARAPCurrency AS ARAPCurrency,
	|	TT_AdditionalData.FixedAsset AS FixedAsset,
	|	TT_AdditionalData.RateOfReturn AS RateOfReturn,
	|	TT_AdditionalData.AdvancePayments AS AdvancePayments,
	|	TT_AdditionalData.PresentValue AS PresentValue,
	|	TT_AdditionalData.NGLV AS NGLV
	|INTO TT_HeaderData_
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS ProvideAssetsToLeasee2_4,
	|	TT_AdditionalData AS TT_AdditionalData
	|WHERE
	|	ProvideAssetsToLeasee2_4.Ref = &Document
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SchedulesData.FixedAsset AS FixedAsset,
	|	SchedulesData.Date AS Date,
	|	SUM(SchedulesData.RentalService) AS RentalService,
	|	SUM(SchedulesData.RentalServiceVAT) AS RentalServiceVAT,
	|	SUM(SchedulesData.Interests) AS Interests
	|INTO TT_SchedulesData
	|FROM
	|	(SELECT
	|		ProvideAssetsToLeasee2_4ServicePaymentSchedule.FixedAsset AS FixedAsset,
	|		ProvideAssetsToLeasee2_4ServicePaymentSchedule.Date AS Date,
	|		ProvideAssetsToLeasee2_4ServicePaymentSchedule.RentalService AS RentalService,
	|		ProvideAssetsToLeasee2_4ServicePaymentSchedule.RentalServiceVAT AS RentalServiceVAT,
	|		0 AS Interests
	|	FROM
	|		Document.ProvideAssetsToLeasee2_4.ServicePaymentSchedule AS ProvideAssetsToLeasee2_4ServicePaymentSchedule
	|			INNER JOIN TT_AdditionalData AS TT_AdditionalData
	|			ON ProvideAssetsToLeasee2_4ServicePaymentSchedule.FixedAsset = TT_AdditionalData.FixedAsset
	|	WHERE
	|		ProvideAssetsToLeasee2_4ServicePaymentSchedule.Ref = &Document
	|		AND ProvideAssetsToLeasee2_4ServicePaymentSchedule.Date >= BEGINOFPERIOD(ProvideAssetsToLeasee2_4ServicePaymentSchedule.Ref.Date, DAY)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InterestAccrualSchedule.FixedAsset,
	|		InterestAccrualSchedule.Date,
	|		0,
	|		0,
	|		InterestAccrualSchedule.Interests - InterestAccrualSchedule.InterestAdjustment
	|	FROM
	|		InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS InterestAccrualSchedule
	|			INNER JOIN TT_AdditionalData AS TT_AdditionalData
	|			ON InterestAccrualSchedule.FixedAsset = TT_AdditionalData.FixedAsset
	|	WHERE
	|		InterestAccrualSchedule.Recorder = &Document
	|		AND InterestAccrualSchedule.Active
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProvideAssetsToLeasee2_4InterestAccrualSchedule.FixedAsset,
	|		ProvideAssetsToLeasee2_4InterestAccrualSchedule.Date,
	|		0,
	|		0,
	|		ProvideAssetsToLeasee2_4InterestAccrualSchedule.Interests
	|	FROM
	|		Document.ProvideAssetsToLeasee2_4.InterestAccrualSchedule AS ProvideAssetsToLeasee2_4InterestAccrualSchedule
	|			INNER JOIN TT_AdditionalData AS TT_AdditionalData
	|			ON ProvideAssetsToLeasee2_4InterestAccrualSchedule.FixedAsset = TT_AdditionalData.FixedAsset
	|	WHERE
	|		ProvideAssetsToLeasee2_4InterestAccrualSchedule.Ref = &Document
	|		AND ProvideAssetsToLeasee2_4InterestAccrualSchedule.Date >= BEGINOFPERIOD(ProvideAssetsToLeasee2_4InterestAccrualSchedule.Ref.Date, DAY)
	|		AND NOT ProvideAssetsToLeasee2_4InterestAccrualSchedule.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProvideAssetsToLeasee2_4FA.FixedAsset,
	|		ProvideAssetsToLeasee2_4FA.RentalEndDate,
	|		TT_AdditionalData.NGLV,
	|		0,
	|		0
	|	FROM
	|		Document.ProvideAssetsToLeasee2_4.FA AS ProvideAssetsToLeasee2_4FA
	|			INNER JOIN TT_AdditionalData AS TT_AdditionalData
	|			ON ProvideAssetsToLeasee2_4FA.FixedAsset = TT_AdditionalData.FixedAsset
	|	WHERE
	|		ProvideAssetsToLeasee2_4FA.Ref = &Document
	|		AND ProvideAssetsToLeasee2_4FA.RentalEndDate <> DATETIME(1,1,1)
	|	) AS SchedulesData
	|
	|GROUP BY
	|	SchedulesData.FixedAsset,
	|	SchedulesData.Date
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_SchedulesData.FixedAsset AS FixedAsset,
	|	SUM(TT_SchedulesData.RentalService) AS AmountOfDebt
	|INTO VT_AmountOfDebt
	|FROM
	|	TT_SchedulesData AS TT_SchedulesData
	|
	|GROUP BY
	|	TT_SchedulesData.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PRESENTATION(TT_HeaderData_.Ref) AS Presentation,
	|	TT_HeaderData_.Ref.Number AS Number,
	|	TT_HeaderData_.Ref.Date AS Date,
	|	TT_HeaderData_.Organization AS Organization,
	|	TT_HeaderData_.Counterparty AS Counterparty,
	|	PRESENTATION(TT_HeaderData_.Counterparty) AS CounterpartyPresentation,
	|	TT_HeaderData_.Contract AS Contract,
	|	PRESENTATION(TT_HeaderData_.Contract) AS ContractPresentation,
	|	PRESENTATION(TT_HeaderData_.VATRate) AS VATRate,
	|	PRESENTATION(TT_HeaderData_.ARAPCurrency) AS ARAPCurrency,
	|	TT_HeaderData_.FixedAsset AS FixedAsset,
	|	PRESENTATION(TT_HeaderData_.FixedAsset) AS FixedAssetPresentation,
	|	TT_HeaderData_.RateOfReturn AS RateOfReturn,
	|	TT_HeaderData_.AdvancePayments AS AdvancePayments,
	|	TT_HeaderData_.PresentValue - TT_HeaderData_.NGLV AS PresentValue,
	|	TT_HeaderData_.NGLV AS NGLV,
	|	ISNULL(TT_SchedulesData.Date, DATETIME(1,1,1)) AS ScheduleDate,
	|	SUM(ISNULL(TT_SchedulesData.RentalService, 0)) AS PaymentAmountWithVAT,
	|	SUM(ISNULL(TT_SchedulesData.RentalService, 0))
	|		- SUM(ISNULL(TT_SchedulesData.RentalServiceVAT, 0)) AS PaymentAmountWithoutVAT,
	|	SUM(ISNULL(TT_SchedulesData.RentalServiceVAT, 0)) AS RentalServiceVAT,
	|	SUM(ISNULL(TT_SchedulesData.Interests, 0)) AS Interests,
	|	ISNULL(VT_AmountOfDebt.AmountOfDebt, 0) AS AmountOfDebt
	|FROM
	|	TT_HeaderData_ AS TT_HeaderData_
	|		LEFT JOIN TT_SchedulesData AS TT_SchedulesData
	|		ON TT_HeaderData_.FixedAsset = TT_SchedulesData.FixedAsset
	|		LEFT JOIN VT_AmountOfDebt AS VT_AmountOfDebt
	|		ON TT_HeaderData_.FixedAsset = VT_AmountOfDebt.FixedAsset
	|
	|GROUP BY
	|	TT_HeaderData_.Ref,
	|	TT_HeaderData_.FixedAsset,
	|	TT_HeaderData_.Organization,
	|	TT_HeaderData_.Counterparty,
	|	TT_HeaderData_.Contract,
	|	TT_HeaderData_.RateOfReturn,
	|	TT_HeaderData_.AdvancePayments,
	|	TT_HeaderData_.PresentValue,
	|	TT_HeaderData_.NGLV,
	|	ISNULL(TT_SchedulesData.Date, DATETIME(1,1,1)),
	|	ISNULL(VT_AmountOfDebt.AmountOfDebt, 0),
	|	PRESENTATION(TT_HeaderData_.VATRate),
	|	PRESENTATION(TT_HeaderData_.ARAPCurrency)
	|
	|ORDER BY
	|	FixedAsset,
	|	ScheduleDate
	|TOTALS
	|	MAX(Counterparty),
	|	MAX(Contract),
	|	MAX(VATRate),
	|	MAX(ARAPCurrency),
	|	MAX(RateOfReturn),
	|	MAX(AdvancePayments),
	|	MAX(PresentValue),
	|	MAX(NGLV),
	|	SUM(PaymentAmountWithVAT),
	|	SUM(PaymentAmountWithoutVAT),
	|	SUM(Interests)
	|BY
	|	Ref,
	|	FixedAsset";
	
	If TypeOf(Document) = Type("DocumentRef.ChangeRentalTerms") Then
		QueryText = StrReplace(QueryText, "ProvideAssetsToLeasee2_4", "ChangeRentalTerms");
	EndIf;
	
	Query.Text = QueryText;
	
	Result = Query.Execute();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
