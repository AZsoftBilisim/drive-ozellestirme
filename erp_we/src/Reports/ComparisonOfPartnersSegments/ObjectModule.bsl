#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;

	// Get period parameters
	DataParameters = SettingsComposer.Settings.DataParameters.Items;
	UserSettings = SettingsComposer.UserSettings.Items;

	StartDate = Date(1,1,1);
	EndDate = Date(1,1,1);
	
	SetDate("StartDate", StartDate);
	SetDate("EndDate", EndDate);

	// Get a list of segments
	Query = New Query(
		"SELECT ALLOWED
		|	PartnersSegments.Ref AS Segment,
		|	PartnersSegments.GenerationMethod,
		|	PartnersSegments.EmployeeResponsible
		|FROM
		|	Catalog.PartnersSegments AS PartnersSegments");

	// Generate a result table
	ResultTable2 = Query.Execute().Unload();
	ResultTable2.Columns.Add("NumberOfPartners");
	ResultTable2.Columns.Add("NumberOfPendingTransactions");
	ResultTable2.Columns.Add("NumberOfLostTransactions");
	ResultTable2.Columns.Add("NumberOfWonTransactions");
	ResultTable2.Columns.Add("PotentialOfPendingTransactions");
	ResultTable2.Columns.Add("LostPotential_");
	ResultTable2.Columns.Add("SavedPotential");
	ResultTable2.Columns.Add("SalesVolume");
	ResultTable2.Columns.Add("SpecificNumberOfPendingTransactions");
	ResultTable2.Columns.Add("SpecificNumberOfLostTransactions");
	ResultTable2.Columns.Add("SpecificNumberOfWonTransactions");
	ResultTable2.Columns.Add("SpecificPotentialOfPendingTransactions");
	ResultTable2.Columns.Add("SpecificLostPotential");
	ResultTable2.Columns.Add("SpecificSavedPotential");
	ResultTable2.Columns.Add("SpecificSalesVolume");
	
	// prepare a request for transaction statistics and sales volumes
	Query = New Query(
		  RequestTextForTransactionStatistics(StartDate,EndDate)
		+ SalesVolumeRequestText(StartDate,EndDate));
	If StartDate    <> Undefined Then
		Query.SetParameter("StartDate", StartDate);
	EndIf;
	If EndDate <> Undefined Then
		Query.SetParameter("EndDate", EndDate);
	EndIf;

	// Fill in the result table
	NumberOfSegments = ResultTable2.Count() - 1;
	For NumberOfSegments_ = 0 To NumberOfSegments Do
		SegmentLine = ResultTable2.Get(NumberOfSegments_);

		// Get a list of segment partners
		MPartners = SegmentsServer.ItemArray(SegmentLine.Segment);

		SegmentLine.NumberOfPartners = MPartners.Count();
		
		// Fill in information on transactions and sales volume
		If MPartners.Count() > 0 Then
			
			Query.SetParameter("Partner", MPartners);
			ResultsArray = Query.ExecuteBatch();
			
			// Get information on segment transactions
			TransactionRequestResult = ResultsArray[0]; // QueryResult
			InfTransactions = TransactionRequestResult.Select();
			If InfTransactions.Next() Then
				SegmentLine.NumberOfPendingTransactions = InfTransactions.NumberOfTransactionsInProgress;
				SegmentLine.NumberOfWonTransactions    = InfTransactions.NumberOfWonTransactions;
				SegmentLine.NumberOfLostTransactions   = InfTransactions.NumberOfLostTransactions;
				SegmentLine.PotentialOfPendingTransactions  = InfTransactions.PotentialInOperation;
				SegmentLine.SavedPotential          = InfTransactions.WonPotential;
				SegmentLine.LostPotential_           = InfTransactions.LostPotential;
				SegmentLine.SpecificNumberOfPendingTransactions =
					SegmentLine.NumberOfPendingTransactions/SegmentLine.NumberOfPartners;
				SegmentLine.SpecificNumberOfWonTransactions    =
					SegmentLine.NumberOfWonTransactions/SegmentLine.NumberOfPartners;
				SegmentLine.SpecificNumberOfLostTransactions   =
					SegmentLine.NumberOfLostTransactions/SegmentLine.NumberOfPartners;
				SegmentLine.SpecificPotentialOfPendingTransactions  =
					SegmentLine.PotentialOfPendingTransactions/SegmentLine.NumberOfPartners;
				SegmentLine.SpecificSavedPotential          =
					SegmentLine.SavedPotential/SegmentLine.NumberOfPartners;
				SegmentLine.SpecificLostPotential           =
					SegmentLine.LostPotential_/SegmentLine.NumberOfPartners;
			EndIf; //Get information on segment transactions

			// Get segment sales volume
			ResultOfSalesRequest = ResultsArray[1]; // QueryResult
			InfVolume = ResultOfSalesRequest.Select();
			If InfVolume.Next() Then
				SegmentLine.SalesVolume = InfVolume.SalesVolume;
				SegmentLine.SpecificSalesVolume =
					SegmentLine.SalesVolume/SegmentLine.NumberOfPartners;
			EndIf; //Get segment sales volume

		EndIf; //Fill in information on transactions and sales volume
	EndDo; //Fill in the result table

	// Fill out the result document
	ResultDocument.Clear();
	TemplateComposer = New DataCompositionTemplateComposer;

	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, 
		SettingsComposer.GetSettings(),
		DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(
		CompositionTemplate,
		New Structure("Segments", ResultTable2),
		DetailsData);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);

	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor, True);
	OutputProcessor.EndOutput();

EndProcedure

#EndRegion

#Region Private

Function QueryTextDateInterval(StartDate, EndDate)
	
	If ValueIsFilled(StartDate) Then
		IntevalText = "
		|		AND SalesOpportunitiesToCustomer.EndDate >= &StartDate";
	Else
		IntevalText = "";
	EndIf;
	If ValueIsFilled(EndDate) Then
		IntevalText = IntevalText + "
		|		AND SalesOpportunitiesToCustomer.EndDate <= &EndDate
		|		AND SalesOpportunitiesToCustomer.EndDate IS NOT NULL";
	EndIf;
	Return IntevalText;
	
EndFunction

Function SalesVolumeRequestText(StartDate, EndDate)

	QueryText =
	"SELECT ALLOWED
	|	ISNULL(SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover), 0) AS SalesVolume
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|		LEFT JOIN AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDate, &EndDate, Auto, ) AS RevenueAndCostOfSalesTurnover
	|		ON DimensionAccounting_1.DimensionKey = RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners
	|WHERE
	|	DimensionAccounting_1.Partner IN(&Partner)";
	
	If Not ValueIsFilled(StartDate) Then
		QueryText = StrReplace(QueryText, "&StartDate", "");
	EndIf;
	If Not ValueIsFilled(EndDate) Then
		QueryText = StrReplace(QueryText, "&EndDate", "");
	EndIf;

	Return QueryText;

EndFunction

Function RequestTextForTransactionStatistics(StartDate, EndDate)

	ConditionTextEndDate = "";
		
	If ValueIsFilled(EndDate) Then
		ConditionTextEndDate = "AND SalesOpportunitiesToCustomer.StartDate <= &EndDate
		|		AND (SalesOpportunitiesToCustomer.EndDate = DATETIME(1, 1, 1)
		|		OR SalesOpportunitiesToCustomer.EndDate > &EndDate)";
	Else
		ConditionTextEndDate = "AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.InProgress)";
	EndIf;
	
	TextOfConditionInterval = QueryTextDateInterval(StartDate,EndDate);
	
	QueryText =
		"SELECT ALLOWED
		|	SUM(NestedQuery.NumberOfTransactionsInProgress) AS NumberOfTransactionsInProgress,
		|	SUM(NestedQuery.NumberOfLostTransactions) AS NumberOfLostTransactions,
		|	SUM(NestedQuery.NumberOfWonTransactions) AS NumberOfWonTransactions,
		|	SUM(NestedQuery.PotentialInOperation) AS PotentialInOperation,
		|	SUM(NestedQuery.LostPotential) AS LostPotential,
		|	SUM(NestedQuery.WonPotential) AS WonPotential
		|FROM
		|	(SELECT
		|		COUNT(*) AS NumberOfTransactionsInProgress,
		|		0 AS NumberOfLostTransactions,
		|		0 AS NumberOfWonTransactions,
		|		ISNULL(SUM(SalesOpportunitiesToCustomer.PotentialSaleAmount), 0) AS PotentialInOperation,
		|		0 AS LostPotential,
		|		0 AS WonPotential
		|	FROM
		|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|	WHERE
		|		SalesOpportunitiesToCustomer.Partner IN(&Partner)
		|		AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.InProgress)
		|		AND &ConditionEndDate
		|
		|	UNION ALL
		|	
		|	SELECT
		|		0,
		|		COUNT(*),
		|		0,
		|		0,
		|		ISNULL(SUM(SalesOpportunitiesToCustomer.PotentialSaleAmount), 0),
		|		0
		|	FROM
		|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|	WHERE
		|		SalesOpportunitiesToCustomer.Partner IN(&Partner)
		|		AND &IntervalCondition
		|		AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Lost)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		0,
		|		0,
		|		COUNT(*),
		|		0,
		|		0,
		|		ISNULL(SUM(SalesOpportunitiesToCustomer.PotentialSaleAmount), 0)
		|	FROM
		|		Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|	WHERE
		|		SalesOpportunitiesToCustomer.Partner IN(&Partner)
		|		AND &IntervalCondition
		|AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)) AS NestedQuery
		|;
		|///////////////////////////////////////////////////////////////////////////////
		|";

	QueryText = StrReplace(QueryText, "AND &ConditionEndDate", ConditionTextEndDate);
	QueryText = StrReplace(QueryText, "AND &IntervalCondition",      TextOfConditionInterval);

	Return QueryText;

EndFunction

Procedure SetDate(Parameter, Date)

	Parameter = SettingsComposer.Settings.DataParameters.Items.Find(Parameter);
	
	If TypeOf(Parameter.Value) = Type("Date") Then
		Date = ?(
			Parameter.Use And ValueIsFilled(Parameter.Value),
			Parameter.Value,
			Undefined);
	Else
		Date = ?(
			Parameter.Use And ValueIsFilled(Parameter.Value.Date),
			Parameter.Value.Date,
			Undefined);
	EndIf;

EndProcedure

#EndRegion

#EndIf
