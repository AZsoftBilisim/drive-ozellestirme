#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region CreatingAndExecutingRequests

Function QueryTextByPartner(MatchingRequestsData)
	
	MatchingRequestsData.Insert("PartnerData",0);
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		TextDetailsOfCounterparty =",
		|	ISNULL(Counterparties.LegalEntityIndividual,VALUE(Enum.LegalEntityIndividual.EmptyRef)) AS LegalEntityIndividual,
		|	ISNULL(Counterparties.TIN,"""") AS TIN,
		|	ISNULL(Counterparties.CRTR, """") AS CRTR";
		
		TextConnectionContractors = "
		|		LEFT JOIN Catalog.Counterparties AS Counterparties
		|		ON Counterparties.Partner = Partners.Ref";
		
	Else
		
		TextDetailsOfCounterparty ="";
		TextConnectionContractors = "";
		
	EndIf;
	
	Return "SELECT TOP 1
	|	Partners.Description,
	|	CASE
	|		WHEN Partners.BusinessRegion = VALUE(Catalog.BusinessRegions.EmptyRef)
	|			THEN &NotSpecified
	|		ELSE Partners.BusinessRegion
	|	END AS BusinessRegion,
	|	CASE
	|		WHEN Partners.MainManager = VALUE(Catalog.Users.EmptyRef)
	|			THEN &NotSpecified
	|		ELSE Partners.MainManager
	|	END AS MainManager,
	|	Partners.RegistrationDate AS RegistrationDate,
	|	Partners.Client,
	|	Partners.Competitor,
	|	Partners.Vendor,
	|	Partners.OtherRelations,
	|	Partners.ServedBySalesRepresentatives,
	|	Partners.Comment,
	|	Partners.AdditionalInformation" + TextDetailsOfCounterparty + "
	|FROM
	|	Catalog.Partners AS Partners " + TextConnectionContractors+ "
	|WHERE
	|	Partners.Ref = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PartnersAdditionalDetails.Property,
	|	PartnersAdditionalDetails.Value
	|FROM
	|	Catalog.Partners.AdditionalAttributes AS PartnersAdditionalDetails
	|WHERE
	|	PartnersAdditionalDetails.Ref = &Partner
	|
	|UNION ALL
	|
	|SELECT
	|	AdditionalInfo.Property,
	|	AdditionalInfo.Value
	|FROM
	|	InformationRegister.AdditionalInfo AS AdditionalInfo
	|WHERE
	|	AdditionalInfo.Object = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function RequestTextForPrimaryInterest(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.InformationRegisters.SourcesOfInitialRequests) Or
		(Not GetFunctionalOption("RecordInitialRequest"))Then
		Return "";
	EndIf; 
	
	MatchingRequestsData.Insert("PrimaryInterest",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED
	|	SourcesOfInitialRequests.ChannelOfInitialRequest,
	|	SourcesOfInitialRequests.SourceOfInitialRequest
	|FROM
	|	InformationRegister.SourcesOfInitialRequests AS SourcesOfInitialRequests
	|WHERE
	|	SourcesOfInitialRequests.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction 

Function RequestTextForPartnerContactInformation(MatchingRequestsData,LastPacketNumber)
	
	MatchingRequestsData.Insert("PartnerContactInformation",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT
	|	PartnersContactInformation.Presentation AS Presentation,
	|	PartnersContactInformation.KindForList  AS ContactInformationKind
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	PartnersContactInformation.Ref = &Partner
	|	AND PartnersContactInformation.KindForList <> VALUE(Catalog.ContactInformationKinds.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction 

Function RequestTextAboutUpstreamPartners(MatchingRequestsData,LastPacketNumber)
	
	MatchingRequestsData.Insert("SuperiorPartners",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT ALLOWED
	|	Partners.ContactInformation.(
	|		Kind,
	|		Presentation
	|	)                         AS ContactInformation,
	|	Partners.MainManager AS MainManager,
	|	Partners.Description     AS Description,
	|	Partners.Ref           AS Ref
	|FROM
	|	InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON PartnerHierarchy.Parent = Partners.Ref
	|WHERE
	|	PartnerHierarchy.Partner = &Partner
	|	AND PartnerHierarchy.Parent <> &Partner
	|TOTALS
	|	COUNT(DISTINCT Ref)
	|BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction 

Function RequestTextForContactPersons(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Catalogs.ContactPersonsForPartners) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("ContactPersons",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT
	|	ContactPersonsForPartners.Description,
	|	ContactPersonsForPartners.JobTitleOnBusinessCard,
	|	ContactPersonsForPartners.ContactPersonRoles.(
	|		ContactRole,
	|		LineNumber
	|	),
	|	ContactPersonsForPartners.ContactInformation.(
	|		Kind,
	|		Presentation
	|	),
	|	ContactPersonsForPartners.Ref AS Ref
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner = &Partner
	|	AND NOT ContactPersonsForPartners.DeletionMark
	|	AND (ContactPersonsForPartners.RelationEndDate = DATETIME(1, 1, 1)
	|			OR ContactPersonsForPartners.RelationEndDate > &CurrentDate)
	|TOTALS
	|	COUNT(DISTINCT Ref)
	|BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function RequestTextAboutCounterparties(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Catalogs.Counterparties) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("Counterparties",LastPacketNumber + 3);
	LastPacketNumber = LastPacketNumber + 3;
	
	Return "
	|SELECT ALLOWED
	|	CounterpartyContactInformation.Ref AS Object,
	|	CounterpartyContactInformation.Kind AS Kind,
	|	MAX(CounterpartyContactInformation.ValidFrom) AS ValidFrom
	|INTO CrossSectionOfContactInformationCounterparties
	|FROM
	|	Catalog.Counterparties.ContactInformation AS CounterpartyContactInformation
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON CounterpartyContactInformation.Ref = Counterparties.Ref
	|WHERE
	|	CounterpartyContactInformation.ValidFrom <= &CurrentDate
	|	AND Counterparties.Partner IN
	|			(SELECT
	|				PartnerHierarchy.Parent
	|			FROM
	|				InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|			WHERE
	|				PartnerHierarchy.Partner = &Partner)
	|	AND NOT Counterparties.DeletionMark
	|
	|GROUP BY
	|	CounterpartyContactInformation.Kind,
	|	CounterpartyContactInformation.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ContactInformation.Kind AS Kind,
	|	ContactInformation.Presentation AS Presentation,
	|	ContactInformation.FieldValues AS FieldValues,
	|	ContactInformation.Ref AS Ref
	|INTO ContactInformationCounterparties
	|FROM
	|	CrossSectionOfContactInformationCounterparties AS ContactInformationSlice
	|		INNER JOIN Catalog.Counterparties.ContactInformation AS ContactInformation
	|		ON ContactInformationSlice.Kind = ContactInformation.Kind
	|			AND ContactInformationSlice.ValidFrom = ContactInformation.ValidFrom
	|			AND ContactInformationSlice.Object = ContactInformation.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Counterparties.Description AS Description,
	|	Counterparties.LegalEntityIndividual AS CounterpartyKind,
	|	Counterparties.Ref AS Ref,
	|	Counterparties.TIN AS TIN,
	|	Counterparties.CRTR AS CRTR,
	|	ContactInformationCounterparties.Kind AS Kind,
	|	ContactInformationCounterparties.Presentation AS Presentation
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|		LEFT JOIN ContactInformationCounterparties AS ContactInformationCounterparties
	|		ON Counterparties.Ref = ContactInformationCounterparties.Ref
	|WHERE
	|	Counterparties.Partner IN
	|			(SELECT
	|				PartnerHierarchy.Parent
	|			FROM
	|				InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|			WHERE
	|				PartnerHierarchy.Partner = &Partner)
	|	AND NOT Counterparties.DeletionMark
	|TOTALS BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

	
EndFunction

Function TextOfRequestAboutCurTransactionsWithClient(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Catalogs.SalesOpportunitiesToCustomer) Or
		(Not GetFunctionalOption("UseSalesOpportunitiesToCustomer"))Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("CurTransactions_",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT ALLOWED
	|	SalesOpportunitiesToCustomer.Description              AS Description,
	|	SalesOpportunitiesToCustomer.EmployeeResponsible             AS Manager,
	|	SalesOpportunitiesToCustomer.PotentialSaleAmount AS PotentialSaleAmount,
	|	StatisticsOfCustomerOpportunities.ProcessStep    AS CurrentStep,
	|	SalesOpportunitiesToCustomer.Ref                    AS Ref,
	|	Constants.ManagementAccountingCurrency       AS Currency
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
	|		ON (StatisticsOfCustomerOpportunities.SalesOpportunity = SalesOpportunitiesToCustomer.Ref),
	|	Constants AS Constants
	|WHERE
	|	SalesOpportunitiesToCustomer.Partner = &Partner
	|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
	|	AND SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.InProgress)
	|	AND ISNULL(StatisticsOfCustomerOpportunities.EndDate, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
	|TOTALS
	|	SUM(PotentialSaleAmount),
	|	COUNT(DISTINCT Ref),
	|	MAX(Currency)
	|BY
	|	SalesOpportunitiesToCustomer.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction 

Function TextOfRequestForUnprocessedAcceptanceCertificates(MatchingRequestsData,LastPacketNumber)
	
	If (Not AccessRight("Read",Metadata.Documents.DiscrepancyReportFollowingShipment))
		Or (Not GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment")) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("ReportsOfDiscrepanciesAfterShipment",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;

	Return "
	|SELECT ALLOWED
	|	DiscrepancyReportFollowingShipment.Currency AS Currency,
	|	DiscrepancyReportFollowingShipment.Number AS Number,
	|	DiscrepancyReportFollowingShipment.Date AS Date,
	|	DiscrepancyReportFollowingShipment.Ref AS Ref,
	|	DiscrepancyReportFollowingShipment.Status AS Status,
	|	DiscrepancyReportFollowingShipment.Manager AS EmployeeResponsible,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum > 0
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum
	|			ELSE 0
	|		END) AS Shortages,
	|	SUM(CASE
	|			WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum - CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument > 0
	|				THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum - CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument
	|			ELSE 0
	|		END) AS Surpluses
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|		INNER JOIN Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|		ON CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = DiscrepancyReportFollowingShipment.Ref
	|			AND (DiscrepancyReportFollowingShipment.Partner = &Partner)
	|			AND (DiscrepancyReportFollowingShipment.Posted)
	|			AND (DiscrepancyReportFollowingShipment.Status <> VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipment.Currency,
	|	DiscrepancyReportFollowingShipment.Status,
	|	DiscrepancyReportFollowingShipment.Number,
	|	DiscrepancyReportFollowingShipment.Manager,
	|	DiscrepancyReportFollowingShipment.Date,
	|	DiscrepancyReportFollowingShipment.Ref
	|TOTALS
	|	COUNT(DISTINCT Ref),
	|	SUM(Shortages),
	|	SUM(Surpluses)
	|BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function QueryTextPendingClaims(MatchingRequestsData,LastPacketNumber)
	
	If (Not AccessRight("Read",Metadata.Catalogs.Complaints))
		Or (Not GetFunctionalOption("RecordComplaints")) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("PendingClaims",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED
	|	CustomerClaims.Ref AS Ref,
	|	CustomerClaims.Description,
	|	CustomerClaims.RegistrationDate AS RegistrationDate,
	|	CustomerClaims.EmployeeResponsible,
	|	CustomerClaims.Status,
	|	CustomerClaims.ReasonForIncurrence
	|FROM
	|	Catalog.Complaints AS CustomerClaims
	|WHERE
	|	(CustomerClaims.Status = VALUE(Enum.CustomerComplaintStatuses.Registered1)
	|	OR CustomerClaims.Status = VALUE(Enum.CustomerComplaintStatuses.InProcessing))
	|
	|	AND (NOT CustomerClaims.DeletionMark)
	|	AND CustomerClaims.Partner = &Partner
	|
	|ORDER BY
	|	RegistrationDate
	|TOTALS
	|	COUNT(DISTINCT Ref)
	|BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function QueryTextTurnovers(MatchingRequestsData,LastPacketNumber)
	
	If (Not AccessRight("Read",Metadata.AccumulationRegisters.RevenueAndCOGS)) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("Turnovers",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover AS RevenueAmountTurnover,
	|	YEAR(RevenueAndCostOfSalesTurnover.Period) AS Period,
	|	Constants.ManagementAccountingCurrency AS Currency
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(
	|			,
	|			,
	|			Year,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|				WHERE
	|					AccountingDimensionByPartners.Partner = &Partner)) AS RevenueAndCostOfSalesTurnover,
	|	Constants AS Constants
	|
	|ORDER BY
	|	Period
	|TOTALS
	|	SUM(RevenueAmountTurnover)
	|BY
	|	ManagementAccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function TextOfRequestForTransactionsInvolvingPartner(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Catalogs.SalesOpportunitiesToCustomer)
		Or (Not GetFunctionalOption("UseSalesOpportunitiesToCustomer")) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("ParticipationInSalesOpportunities",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 2;
	
	Return "SELECT ALLOWED
	|	COUNT(DISTINCT NestedQuery.SalesOpportunity) AS TransactionNumber,
	|	SUM(NestedQuery.PotentialSaleAmount) AS PotentialSaleAmount,
	|	Constants.ManagementAccountingCurrency AS Currency
	|FROM
	|	(SELECT
	|		SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
	|		SalesOpportunitiesToCustomer.PotentialSaleAmount AS PotentialSaleAmount
	|	FROM
	|		Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
	|			INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|			ON SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref
	|	WHERE
	|		SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.InProgress)
	|		AND SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = &Partner
	|		AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
	|		AND SalesOpportunitiesToCustomer.Partner <> &Partner
	|	
	|	GROUP BY
	|		SalesOpportunitiesToCustomer.Ref,
	|		SalesOpportunitiesToCustomer.PotentialSaleAmount) AS NestedQuery,
	|	Constants AS Constants
	|
	|GROUP BY
	|	Constants.ManagementAccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
	|	SalesOpportunitiesToCustomer.PotentialSaleAmount AS PotentialSaleAmount,
	|	SalesOpportunitiesToCustomerPartnersAndContactPersons.PartnerSRole,
	|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson,
	|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactRole,
	|	SalesOpportunitiesToCustomer.Description,
	|	StatisticsOfCustomerOpportunities.ProcessStep AS CurrentStep
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
	|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref
	|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
	|		ON (StatisticsOfCustomerOpportunities.SalesOpportunity = SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref),
	|	Constants AS Constants
	|WHERE
	|	SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.InProgress)
	|	AND SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = &Partner
	|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
	|	AND SalesOpportunitiesToCustomer.Partner <> &Partner
	|	AND ISNULL(StatisticsOfCustomerOpportunities.EndDate, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
	|TOTALS
	|	MAX(PotentialSaleAmount)
	|BY
	|	SalesOpportunity,
	|	CurrentStep
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function TextOfRequestAboutPartnerSParticipationInOtherProjects(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Catalogs.MarketingActivities) 
		And Not AccessRight("Read",Metadata.Catalogs.Projects) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("OtherProjects",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 2;
	
	Return "
	|SELECT ALLOWED
	|	NestedQuery.Kind,
	|	COUNT(DISTINCT NestedQuery.Ref) AS Count
	|FROM
	|	(SELECT DISTINCT
	|		MarketingActivities.Ref AS Ref,
	|		&StringMarketingEvent AS Kind
	|	FROM
	|		Catalog.MarketingActivities.PartnersAndContactPersons AS MarketingActivitiesPartnersAndContactPersons
	|			INNER JOIN Catalog.MarketingActivities AS MarketingActivities
	|			ON MarketingActivitiesPartnersAndContactPersons.Ref = MarketingActivities.Ref
	|	WHERE
	|		(NOT MarketingActivities.DeletionMark)
	|		AND MarketingActivities.PartnersAndContactPersons.Partner = &Partner
	|		AND (NOT MarketingActivities.Completed)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Projects.Ref,
	|		&ProjectLine
	|	FROM
	|		Catalog.Projects.PartnersAndContactPersons AS ProjectsPartnersAndContactPersons
	|			LEFT JOIN Catalog.Projects AS Projects
	|			ON ProjectsPartnersAndContactPersons.Ref = Projects.Ref
	|	WHERE
	|		(NOT Projects.DeletionMark)
	|		AND (NOT Projects.Completed)
	|		AND Projects.PartnersAndContactPersons.Partner = &Partner) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Kind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MarketingActivities.Ref AS Ref,
	|	MarketingActivities.Description,
	|	MarketingActivitiesPartnersAndContactPersons.PartnerSRole,
	|	MarketingActivitiesPartnersAndContactPersons.ContactPerson,
	|	&StringMarketingEvent AS Kind,
	|	"""" AS ContactRole,
	|	MarketingActivities.EmployeeResponsible
	|FROM
	|	Catalog.MarketingActivities.PartnersAndContactPersons AS MarketingActivitiesPartnersAndContactPersons
	|		INNER JOIN Catalog.MarketingActivities AS MarketingActivities
	|		ON MarketingActivitiesPartnersAndContactPersons.Ref = MarketingActivities.Ref
	|WHERE
	|	(NOT MarketingActivities.DeletionMark)
	|	AND (NOT MarketingActivities.Completed)
	|	AND MarketingActivitiesPartnersAndContactPersons.Partner = &Partner
	|
	|UNION ALL
	|
	|SELECT
	|	Projects.Ref,
	|	Projects.Description,
	|	ProjectsPartnersAndContactPersons.PartnerSRole,
	|	ProjectsPartnersAndContactPersons.ContactPerson,
	|	&ProjectLine,
	|	"""",
	|	Projects.EmployeeResponsible
	|FROM
	|	Catalog.Projects.PartnersAndContactPersons AS ProjectsPartnersAndContactPersons
	|		LEFT JOIN Catalog.Projects AS Projects
	|		ON ProjectsPartnersAndContactPersons.Ref = Projects.Ref
	|WHERE
	|	(NOT Projects.DeletionMark)
	|	AND (NOT Projects.Completed)
	|	AND Projects.PartnersAndContactPersons.Partner = &Partner
	|TOTALS BY
	|	Kind,
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function RequestTextForOrdersToSupplier(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Documents.PurchaseOrder)
		Or Not GetFunctionalOption("UsePurchaseOrders") Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("OrdersToSupplier",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED
	|	DocumentPurchaseOrder.Ref AS Ref,
	|	DocumentPurchaseOrder.Number AS Number,
	|	DocumentPurchaseOrder.Date AS Date,
	|	DocumentPurchaseOrder.Currency AS Currency,
	|	DocumentPurchaseOrder.Manager AS EmployeeResponsible,
	|	DocumentPurchaseOrder.DocumentAmount AS DocumentAmount,
	|	PurchaseOrderStates.State AS State,
	|	CASE WHEN PurchaseOrderStates.EventDate <> DATETIME(1, 1, 1)
	|			AND &CurrentDate > PurchaseOrderStates.EventDate 
	|		THEN TRUE
	|	ELSE FALSE
	|	END AS Overdue
	|FROM
	|	InformationRegister.PurchaseOrderStates AS PurchaseOrderStates
	|		LEFT JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
	|		ON (PurchaseOrderStates.OrderDocument = DocumentPurchaseOrder.Ref)
	|WHERE
	|	DocumentPurchaseOrder.Partner = &Partner
	|	AND PurchaseOrderStates.State <> VALUE(Enum.PurchaseOrderStates.Closed) 
	|TOTALS
	|	COUNT(DISTINCT Ref),
	|	SUM(DocumentAmount)
	|BY
	|	OVERALL,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

EndFunction

Function RequestTextForPartnerOrders(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Documents.SalesOrder)
		Or Not GetFunctionalOption("UseSalesOrders") Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("Orders",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT ALLOWED
	|	DocumentSalesOrder.Ref AS Ref,
	|	DocumentSalesOrder.Number AS Number,
	|	DocumentSalesOrder.Date AS Date,
	|	DocumentSalesOrder.Currency AS Currency,
	|	DocumentSalesOrder.DocumentAmount AS DocumentAmount,
	|	DocumentSalesOrder.Status AS Status,
	|	DocumentSalesOrder.Manager AS EmployeeResponsible,
	|	SalesOrderStates.State AS State,
	|	CASE WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|			AND &CurrentDate > SalesOrderStates.EventDate 
	|		THEN TRUE
	|	ELSE FALSE
	|	END AS Overdue
	|FROM
	|	InformationRegister.SalesOrderStates AS SalesOrderStates
	|		LEFT JOIN Document.SalesOrder AS DocumentSalesOrder
	|		ON (SalesOrderStates.OrderDocument = DocumentSalesOrder.Ref)
	|WHERE
	|	DocumentSalesOrder.Partner = &Partner
	|	AND SalesOrderStates.State <> VALUE(Enum.SalesOrderStates.Closed)
	|TOTALS
	|	COUNT(DISTINCT Ref),
	|	SUM(DocumentAmount)
	|BY
	|	OVERALL,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function TextOfRequestForPartnerRefundRequests(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
		Or Not GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers") Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("RequestsForReturn",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT ALLOWED
	|	DocumentRequest.Ref AS Ref,
	|	DocumentRequest.Number AS Number,
	|	DocumentRequest.Date AS Date,
	|	DocumentRequest.Currency AS Currency,
	|	DocumentRequest.DocumentAmount AS DocumentAmount,
	|	DocumentRequest.Status AS Status,
	|	DocumentRequest.Manager AS EmployeeResponsible,
	|	SalesOrderStates.State AS State,
	|	CASE WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|			AND &CurrentDate > SalesOrderStates.EventDate 
	|		THEN TRUE
	|	ELSE FALSE
	|	END AS Overdue
	|FROM
	|	InformationRegister.SalesOrderStates AS SalesOrderStates
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequest
	|		ON (SalesOrderStates.OrderDocument = DocumentRequest.Ref)
	|WHERE
	|	DocumentRequest.Partner = &Partner
	|	AND SalesOrderStates.State <> VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed)
	|TOTALS
	|	COUNT(DISTINCT Ref),
	|	SUM(DocumentAmount)
	|BY
	|	OVERALL,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function TextOfRequestForSettlementsWithClient(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments)
		Or Not AccessRight("Read",Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("SettlementsWithClient",LastPacketNumber + 6);
	LastPacketNumber = LastPacketNumber + 6;
	
	QueryText = "
	|SELECT DISTINCT
	|	AccountingDimensionByPartners.DimensionKey
	|INTO SelectingPartnerAnalytics
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	MIN(DATEADD(Jobs.Month, DAY, -1)) AS CurrentPeriod_,
	|	TRUE AS PaymentsAreIrrelevant
	|INTO Boundaries
	|FROM
	|	InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
	|WHERE
	|	Jobs.AccountingDimensionByPartners IN
	|			(SELECT
	|				SelectingPartnerAnalytics.DimensionKey
	|			FROM
	|				SelectingPartnerAnalytics AS SelectingPartnerAnalytics)
	|	AND Jobs.Month < &CurrentDate
	|	AND NOT &NewOnlineARAPAccounting
	|GROUP BY
	|	Jobs.AccountingDimensionByPartners
	|INDEX BY
	|	AccountingDimensionByPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CustomersARAPAccounting.AccountingDimensionByPartners,
	|	CustomersARAPAccounting.SalesOrder,
	|	CustomersARAPAccounting.Currency,
	|	CustomersARAPAccounting.ARAPDocument,
	|	Balance.PaymentDate,
	|	-(CustomersARAPAccounting.ForReturnBalance + CustomersARAPAccounting.PrepaymentBalance) AS AccountsPayableOfCompany,
	|	CustomersARAPAccounting.DebtBalance AS CustomerAccountsReceivable,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Counterparty
	|INTO TableOfArrears
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
	|			&CurrentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					SelectingPartnerAnalytics.DimensionKey
	|				FROM
	|					SelectingPartnerAnalytics AS SelectingPartnerAnalytics)) AS CustomersARAPAccounting
	|		{INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey}
	|
	|	INNER JOIN CustomerBalanceTable AS Balance
	|	ON CustomersARAPAccounting.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|		AND CustomersARAPAccounting.SalesOrder = Balance.SalesOrder
	|		AND CustomersARAPAccounting.Currency = Balance.Currency
	|		AND CustomersARAPAccounting.ARAPDocument = Balance.ARAPDocument
	|WHERE
	|	DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND NOT &NewOnlineARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationsByTerms.AccountingDimensionByPartners                      AS AccountingDimensionByPartners,
	|	CalculationsByTerms.ARAPObject                                 AS SalesOrder,
	|	CalculationsByTerms.Currency                                         AS Currency,
	|	CalculationsByTerms.ARAPDocument                              AS ARAPDocument,
	|	CalculationsByTerms.PlannedRepaymentDate                         AS PaymentDate,
	|	CalculationsByTerms.PrepaymentBalance                              AS AccountsPayableOfCompany,
	|	CalculationsByTerms.DebtBalance                                    AS CustomerAccountsReceivable,
	|	DimensionAccounting_1.Partner                                         AS Partner,
	|	DimensionAccounting_1.Organization                                     AS Organization,
	|	DimensionAccounting_1.Counterparty                                      AS Counterparty
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
	|			&CurrentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					SelectingPartnerAnalytics.DimensionKey
	|				FROM
	|					SelectingPartnerAnalytics AS SelectingPartnerAnalytics)) AS CalculationsByTerms
	|		{INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey}
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TableOfArrears.PaymentDate AS StartDate,
	|	WorkSchedules.Date AS EndDate,
	|	CASE
	|		WHEN WorkSchedules.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Work) OR WorkSchedules.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Preholiday)
	|			THEN 1
	|		ELSE 0
	|	END AS WorkingDay
	|INTO Schedules
	|FROM
	|	TableOfArrears AS TableOfArrears
	|		LEFT JOIN InformationRegister.BusinessCalendarData AS WorkSchedules
	|		ON (WorkSchedules.BusinessCalendar = &Calendar)
	|WHERE
	|	WorkSchedules.Date BETWEEN TableOfArrears.PaymentDate AND &CurrentDate
	|	AND TableOfArrears.PaymentDate <> DATETIME(1, 1, 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.StartDate AS StartDate,
	|	NestedQuery.EndDate AS EndDate,
	|	ISNULL(SUM(Schedules.WorkingDay), 0) AS DaysCount
	|INTO DateDifferences
	|FROM
	|	Schedules AS NestedQuery
	|		LEFT JOIN Schedules AS Schedules
	|		ON NestedQuery.StartDate = Schedules.StartDate
	|			AND NestedQuery.EndDate > Schedules.EndDate
	|WHERE
	|	NestedQuery.EndDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|
	|GROUP BY
	|	NestedQuery.StartDate,
	|	NestedQuery.EndDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	If Not ValueIsFilled(DebtClassificationOption) Then 
		QueryText = QueryText + "
		|SELECT
		|	TableOfArrears.SalesOrder,
		|	TableOfArrears.Currency AS Currency,
		|	ISNULL(Boundaries.CurrentPeriod_, UNDEFINED) AS DateCalculationsWereUpdated,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.ARAPDocument
		|		ELSE UNDEFINED
		|	END AS ARAPDocument,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.PaymentDate
		|		ELSE UNDEFINED
		|	END AS PaymentDate,
		|	TableOfArrears.AccountsPayableOfCompany AS AccountsPayableOfCompany,
		|	TableOfArrears.CustomerAccountsReceivable AS CustomerAccountsReceivable,
		|	CASE
		|		WHEN NOT Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN 0
		|		WHEN CASE
		|				WHEN NOT DateDifferences.DaysCount IS NULL 
		|					THEN CASE
		|							WHEN DateDifferences.DaysCount > 0
		|								THEN DateDifferences.DaysCount
		|							ELSE 0
		|						END
		|				ELSE CASE
		|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|							THEN 0
		|						ELSE CASE
		|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|									THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|								ELSE 0
		|							END
		|					END
		|			END = 0
		|			THEN 0
		|		ELSE TableOfArrears.CustomerAccountsReceivable
		|	END AS OverdueCustomerDebt,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN CASE
		|					WHEN NOT DateDifferences.DaysCount IS NULL 
		|						THEN CASE
		|								WHEN DateDifferences.DaysCount > 0
		|									THEN DateDifferences.DaysCount
		|								ELSE &NotOverdue
		|							END
		|					ELSE CASE
		|							WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|								THEN &NotOverdue
		|							ELSE CASE
		|									WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|										THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|									ELSE &NotOverdue
		|								END
		|						END
		|				END
		|		ELSE &PaymentsAreIrrelevant
		|	END AS IntervalName
		|FROM
		|	TableOfArrears AS TableOfArrears
		|		LEFT JOIN Boundaries AS Boundaries
		|		ON TableOfArrears.AccountingDimensionByPartners = Boundaries.AccountingDimensionByPartners
		|		LEFT JOIN DateDifferences AS DateDifferences
		|		ON (DateDifferences.StartDate = TableOfArrears.PaymentDate)
		|TOTALS
		|	SUM(AccountsPayableOfCompany),
		|	SUM(CustomerAccountsReceivable),
		|	SUM(OverdueCustomerDebt)
		|BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		

	Else
		QueryText = QueryText + "
		|SELECT 
		|	TableOfArrears.SalesOrder,
		|	TableOfArrears.Currency AS Currency,
		|	ISNULL(Boundaries.CurrentPeriod_, UNDEFINED) AS DateCalculationsWereUpdated,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.ARAPDocument
		|		ELSE UNDEFINED
		|	END AS ARAPDocument,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.PaymentDate
		|		ELSE UNDEFINED
		|	END AS PaymentDate,
		|	TableOfArrears.AccountsPayableOfCompany AS AccountsPayableOfCompany,
		|	TableOfArrears.CustomerAccountsReceivable AS CustomerAccountsReceivable,
		|	CASE
		|		WHEN (NOT Boundaries.PaymentsAreIrrelevant IS NULL )
		|			THEN 0
		|		WHEN (NOT DateDifferences.DaysCount IS NULL )
		|			THEN CASE
		|					WHEN DateDifferences.DaysCount > 0
		|						THEN DateDifferences.DaysCount
		|					ELSE 0
		|				END
		|		ELSE CASE
		|				WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|					THEN 0
		|				ELSE CASE
		|						WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|							THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|						ELSE 0
		|					END
		|			END
		|	END AS DaysCount,
		|	CASE
		|		WHEN (NOT Boundaries.PaymentsAreIrrelevant IS NULL )
		|			THEN 0
		|		WHEN CASE
		|				WHEN (NOT DateDifferences.DaysCount IS NULL )
		|					THEN CASE
		|							WHEN DateDifferences.DaysCount > 0
		|								THEN DateDifferences.DaysCount
		|							ELSE 0
		|						END
		|				ELSE CASE
		|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|							THEN 0
		|						ELSE CASE
		|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|									THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|								ELSE 0
		|							END
		|					END
		|			END = 0
		|			THEN 0
		|		ELSE TableOfArrears.CustomerAccountsReceivable
		|	END AS OverdueCustomerDebt,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN ISNULL(Intervals.IntervalName, &NotOverdue)
		|		ELSE &PaymentsAreIrrelevant
		|	END AS IntervalName
		|FROM
		|	TableOfArrears AS TableOfArrears
		|		LEFT JOIN Boundaries AS Boundaries
		|		ON TableOfArrears.AccountingDimensionByPartners = Boundaries.AccountingDimensionByPartners
		|		LEFT JOIN DateDifferences AS DateDifferences
		|		ON (DateDifferences.StartDate = TableOfArrears.PaymentDate)
		|		LEFT JOIN Catalog.TimeBucketsForAgingAnalysis.Intervals AS Intervals
		|		ON (Intervals.Ref = &DebtClassificationOption)
		|			AND (CASE
		|				WHEN (NOT DateDifferences.DaysCount IS NULL )
		|					THEN CASE
		|							WHEN DateDifferences.DaysCount > 0
		|								THEN DateDifferences.DaysCount
		|							ELSE 0
		|						END
		|				ELSE CASE
		|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|							THEN 0
		|						ELSE CASE
		|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|									THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|								ELSE 0
		|							END
		|					END
		|			END BETWEEN Intervals.LowerBoundOfInterval AND Intervals.UpperBoundOfInterval)
		|ORDER BY
		|	PaymentDate ASC
		|TOTALS
		|	SUM(AccountsPayableOfCompany),
		|	SUM(CustomerAccountsReceivable),
		|	SUM(OverdueCustomerDebt)
		|BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;

	Return QueryText;
	
EndFunction

Function TextOfRequestForSettlementsWithSupplier(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments) 
		Or Not AccessRight("Read",Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("SettlementsWithSupplier",LastPacketNumber + 6);
	LastPacketNumber = LastPacketNumber + 6;
	
	QueryText = "
	|SELECT DISTINCT
	|	AccountingDimensionByPartners.DimensionKey
	|INTO SelectionOfPartnerAnalyticsSuppliers
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Partner = &Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	MIN(DATEADD(Jobs.Month, DAY, -1)) AS CurrentPeriod_,
	|	TRUE AS PaymentsAreIrrelevant
	|INTO BordersSuppliers
	|FROM
	|	InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
	|WHERE
	|	Jobs.AccountingDimensionByPartners IN
	|			(SELECT
	|				SelectingPartnerAnalytics.DimensionKey
	|			FROM
	|				SelectionOfPartnerAnalyticsSuppliers AS SelectingPartnerAnalytics)
	|	AND Jobs.Month <= &CurrentDate
	|	AND NOT &NewOnlineARAPAccounting
	|GROUP BY
	|	Jobs.AccountingDimensionByPartners
	|INDEX BY
	|	AccountingDimensionByPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	VendorsARAPAccounting.AccountingDimensionByPartners,
	|	VendorsARAPAccounting.PurchaseOrder,
	|	VendorsARAPAccounting.Currency,
	|	VendorsARAPAccounting.ARAPDocument,
	|	Balance.PaymentDate,
	|	-(VendorsARAPAccounting.ForReturnBalance + VendorsARAPAccounting.PrepaymentBalance) AS DebtOfSupplier,
	|	VendorsARAPAccounting.DebtBalance AS AccountsPayableOfCompany,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Counterparty
	|INTO TableOfArrearsSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
	|			&CurrentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					SelectingPartnerAnalytics.DimensionKey
	|				FROM
	|					SelectionOfPartnerAnalyticsSuppliers AS SelectingPartnerAnalytics)) AS VendorsARAPAccounting
	|		{INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey}
	|
	|	INNER JOIN TableOfSupplierBalances AS Balance
	|	ON VendorsARAPAccounting.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|		AND VendorsARAPAccounting.PurchaseOrder = Balance.PurchaseOrder
	|		AND VendorsARAPAccounting.Currency = Balance.Currency
	|		AND VendorsARAPAccounting.ARAPDocument = Balance.ARAPDocument
	|WHERE
	|	DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationsByTerms.AccountingDimensionByPartners                      AS AccountingDimensionByPartners,
	|	CalculationsByTerms.ARAPObject                                 AS PurchaseOrder,
	|	CalculationsByTerms.Currency                                         AS Currency,
	|	CalculationsByTerms.ARAPDocument                              AS ARAPDocument,
	|	CalculationsByTerms.PlannedRepaymentDate                         AS PaymentDate,
	|	CalculationsByTerms.DebtBalance                                    AS DebtOfSupplier,
	|	CalculationsByTerms.PrepaymentBalance                              AS AccountsPayableOfCompany,
	|	DimensionAccounting_1.Partner                                         AS Partner,
	|	DimensionAccounting_1.Organization                                     AS Organization,
	|	DimensionAccounting_1.Counterparty                                      AS Counterparty
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
	|			&CurrentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					SelectingPartnerAnalytics.DimensionKey
	|				FROM
	|					SelectionOfPartnerAnalyticsSuppliers AS SelectingPartnerAnalytics)) AS CalculationsByTerms
	|		{INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey}
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TableOfArrears.PaymentDate AS StartDate,
	|	WorkSchedules.Date AS EndDate,
	|	CASE
	|		WHEN WorkSchedules.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Work) OR WorkSchedules.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Preholiday)
	|			THEN 1
	|		ELSE 0
	|	END AS WorkingDay
	|INTO GraphicsSuppliers
	|FROM
	|	TableOfArrearsSuppliers AS TableOfArrears
	|		LEFT JOIN InformationRegister.BusinessCalendarData AS WorkSchedules
	|		ON (WorkSchedules.BusinessCalendar = &Calendar)
	|WHERE
	|	WorkSchedules.Date BETWEEN TableOfArrears.PaymentDate AND &CurrentDate
	|	AND TableOfArrears.PaymentDate <> DATETIME(1, 1, 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.StartDate AS StartDate,
	|	NestedQuery.EndDate AS EndDate,
	|	ISNULL(SUM(Schedules.WorkingDay), 0) AS DaysCount
	|INTO DateDifferencesSuppliers
	|FROM
	|	GraphicsSuppliers AS NestedQuery
	|		LEFT JOIN GraphicsSuppliers AS Schedules
	|		ON NestedQuery.StartDate = Schedules.StartDate
	|			AND NestedQuery.EndDate > Schedules.EndDate
	|WHERE
	|	NestedQuery.EndDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|
	|GROUP BY
	|	NestedQuery.StartDate,
	|	NestedQuery.EndDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

	If Not ValueIsFilled(DebtClassificationOption) Then 
		QueryText = QueryText + "
		|SELECT
		|	TableOfArrears.PurchaseOrder,
		|	TableOfArrears.Currency AS Currency,
		|	ISNULL(Boundaries.CurrentPeriod_, UNDEFINED) AS DateCalculationsWereUpdated,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.ARAPDocument
		|		ELSE UNDEFINED
		|	END AS ARAPDocument,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.PaymentDate
		|		ELSE UNDEFINED
		|	END AS PaymentDate,
		|	-TableOfArrears.AccountsPayableOfCompany AS AccountsPayableOfCompany,
		|	TableOfArrears.DebtOfSupplier AS DebtOfSupplier,
		|	CASE
		|		WHEN NOT Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN &PaymentsAreIrrelevant
		|		WHEN NOT DateDifferences.DaysCount IS NULL 
		|			THEN CASE
		|					WHEN DateDifferences.DaysCount > 0
		|						THEN DateDifferences.DaysCount
		|					ELSE &NotOverdue
		|				END
		|		ELSE CASE
		|				WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|					THEN &NotOverdue
		|				ELSE CASE
		|						WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|							THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|						ELSE &NotOverdue
		|					END
		|			END
		|	END AS IntervalName,
		|	CASE
		|		WHEN NOT Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN 0
		|		WHEN CASE
		|				WHEN NOT DateDifferences.DaysCount IS NULL 
		|					THEN CASE
		|							WHEN DateDifferences.DaysCount > 0
		|								THEN DateDifferences.DaysCount
		|							ELSE 0
		|						END
		|				ELSE CASE
		|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|							THEN 0
		|						ELSE CASE
		|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|									THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|								ELSE 0
		|							END
		|					END
		|			END = 0
		|			THEN 0
		|		ELSE -TableOfArrears.AccountsPayableOfCompany
		|	END AS OurDebtOverdue
		|FROM
		|	TableOfArrearsSuppliers AS TableOfArrears
		|		LEFT JOIN BordersSuppliers AS Boundaries
		|		ON TableOfArrears.AccountingDimensionByPartners = Boundaries.AccountingDimensionByPartners
		|		LEFT JOIN DateDifferencesSuppliers AS DateDifferences
		|		ON (DateDifferences.StartDate = TableOfArrears.PaymentDate)
		|TOTALS
		|	SUM(AccountsPayableOfCompany),
		|	SUM(DebtOfSupplier),
		|	SUM(OurDebtOverdue)
		|BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	
	Else
		
		QueryText = QueryText + "
		|SELECT
		|	TableOfArrears.PurchaseOrder,
		|	TableOfArrears.Currency AS Currency,
		|	ISNULL(Boundaries.CurrentPeriod_, UNDEFINED) AS DateCalculationsWereUpdated,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.ARAPDocument
		|		ELSE UNDEFINED
		|	END AS ARAPDocument,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN TableOfArrears.PaymentDate
		|		ELSE UNDEFINED
		|	END AS PaymentDate,
		|	-TableOfArrears.AccountsPayableOfCompany AS AccountsPayableOfCompany,
		|	TableOfArrears.DebtOfSupplier AS DebtOfSupplier,
		|	CASE
		|		WHEN (NOT Boundaries.PaymentsAreIrrelevant IS NULL )
		|			THEN 0
		|		WHEN (NOT DateDifferences.DaysCount IS NULL )
		|			THEN CASE
		|					WHEN DateDifferences.DaysCount > 0
		|						THEN DateDifferences.DaysCount
		|					ELSE 0
		|				END
		|		ELSE CASE
		|				WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|					THEN 0
		|				ELSE CASE
		|						WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|							THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|						ELSE 0
		|					END
		|			END
		|	END AS DaysCount,
		|	CASE
		|		WHEN (NOT Boundaries.PaymentsAreIrrelevant IS NULL )
		|			THEN 0
		|		WHEN CASE
		|				WHEN (NOT DateDifferences.DaysCount IS NULL )
		|					THEN CASE
		|							WHEN DateDifferences.DaysCount > 0
		|								THEN DateDifferences.DaysCount
		|							ELSE 0
		|						END
		|				ELSE CASE
		|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|							THEN 0
		|						ELSE CASE
		|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|									THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|								ELSE 0
		|							END
		|					END
		|			END = 0
		|			THEN 0
		|		ELSE -TableOfArrears.AccountsPayableOfCompany
		|	END AS OurDebtOverdue,
		|	CASE
		|		WHEN Boundaries.PaymentsAreIrrelevant IS NULL 
		|			THEN ISNULL(Intervals.IntervalName, &NotOverdue)
		|		ELSE &PaymentsAreIrrelevant
		|	END AS IntervalName
		|FROM
		|	TableOfArrearsSuppliers AS TableOfArrears
		|		LEFT JOIN BordersSuppliers AS Boundaries
		|		ON TableOfArrears.AccountingDimensionByPartners = Boundaries.AccountingDimensionByPartners
		|		LEFT JOIN DateDifferencesSuppliers AS DateDifferences
		|		ON (DateDifferences.StartDate = TableOfArrears.PaymentDate)
		|		LEFT JOIN Catalog.TimeBucketsForAgingAnalysis.Intervals AS Intervals
		|		ON (Intervals.Ref = &DebtClassificationOption)
		|			AND (CASE
		|				WHEN (NOT DateDifferences.DaysCount IS NULL )
		|					THEN CASE
		|							WHEN DateDifferences.DaysCount > 0
		|								THEN DateDifferences.DaysCount
		|							ELSE 0
		|						END
		|				ELSE CASE
		|						WHEN TableOfArrears.PaymentDate = DATETIME(1, 1, 1)
		|							THEN 0
		|						ELSE CASE
		|								WHEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY) > 0
		|									THEN DATEDIFF(TableOfArrears.PaymentDate, &CurrentDate, DAY)
		|								ELSE 0
		|							END
		|					END
		|			END BETWEEN Intervals.LowerBoundOfInterval AND Intervals.UpperBoundOfInterval)
		|ORDER BY
		|	PaymentDate ASC
		|TOTALS
		|	SUM(AccountsPayableOfCompany),
		|	SUM(DebtOfSupplier),
		|	SUM(OurDebtOverdue)
		|BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	Return QueryText;
	
EndFunction 

Function RequestTextForAvailableAgreements(MatchingRequestsData,LastPacketNumber)
	
	If Not GetFunctionalOption("ToUseTermsOfSales")
		Or Not AccessRight("Read",Metadata.Catalogs.TermsOfSale) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("AvailableAgreements",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED
	        |	CatalogTermsOfSale.Ref AS Ref,
	        |	CatalogTermsOfSale.Description,
	        |	CatalogTermsOfSale.Currency,
	        |	CASE
	        |		WHEN CatalogTermsOfSale.ValidityEndDate = DATETIME(1, 1, 1)
	        |			THEN &StringWithoutRestriction
	        |		ELSE CatalogTermsOfSale.ValidityEndDate
	        |	END AS ValidityPeriod,
	        |	CASE
	        |		WHEN CatalogTermsOfSale.Standard_
	        |			THEN &LineTypical
	        |		ELSE &LineIndividual
	        |	END AS Standard_
	        |FROM
	        |	Catalog.TermsOfSale AS CatalogTermsOfSale
	        |		LEFT JOIN Catalog.PaymentSchedules AS PaymentSchedules
	        |		ON CatalogTermsOfSale.PaymentSchedule = PaymentSchedules.Ref
	        |WHERE
	        |	CatalogTermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	        |	AND (CatalogTermsOfSale.Partner = &Partner
	        |			OR CatalogTermsOfSale.PartnersSegment IN
	        |				(SELECT
	        |					SegmentPartners.Segment
	        |				FROM
	        |					InformationRegister.SegmentPartners AS SegmentPartners
	        |				WHERE
	        |					SegmentPartners.Partner = &Partner)
	        |			OR CatalogTermsOfSale.Standard_
	        |				AND CatalogTermsOfSale.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef))
	        |	AND NOT CatalogTermsOfSale.DeletionMark
	        |	AND &ToUseTermsOfSales = TRUE
	        |	AND CASE
	        |			WHEN &OnlyStandard = TRUE
	        |					AND &OnlyPersonal = FALSE
	        |					AND CatalogTermsOfSale.Standard_
	        |				THEN TRUE
	        |			WHEN &OnlyPersonal = TRUE
	        |					AND NOT &OnlyStandard = TRUE
	        |					AND NOT CatalogTermsOfSale.Standard_
	        |				THEN TRUE
	        |			WHEN &OnlyStandard = FALSE
	        |					AND &OnlyPersonal = FALSE
	        |				THEN TRUE
	        |			ELSE FALSE
	        |		END
	        |TOTALS
	        |	COUNT(DISTINCT Ref)
	        |BY
	        |	OVERALL
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
	
EndFunction 

Function RequestTextForAgreementsWithSupplier(MatchingRequestsData,LastPacketNumber)

	If Not AccessRight("Read",Metadata.Catalogs.TermsOfPurchaseFromVendors) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("TermsOfPurchase",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT ALLOWED
	|	TermsOfPurchaseFromVendors.Ref AS Ref,
	|	TermsOfPurchaseFromVendors.Currency AS Currency,
	|	TermsOfPurchaseFromVendors.Manager AS EmployeeResponsible,
	|	CASE
	|		WHEN TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
	|			THEN &StringWithoutRestriction
	|		ELSE TermsOfPurchaseFromVendors.ValidityEndDate
	|	END AS ValidityPeriod,
	|	TermsOfPurchaseFromVendors.Description
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|WHERE
	|	TermsOfPurchaseFromVendors.Partner = &Partner
	|	AND (NOT TermsOfPurchaseFromVendors.DeletionMark)
	|	AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|TOTALS
	|	COUNT(DISTINCT Ref)
	|BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

EndFunction

Function RequestTextForUnprocessedInteractions(MatchingRequestsData,LastPacketNumber)
	
	If (Not GetFunctionalOption("UseEmailClient"))
	     Or (Not AccessRight("Read",Metadata.Documents.PlannedInteraction)
	     And Not AccessRight("Read",Metadata.Documents.Meeting)
	     And Not AccessRight("Read",Metadata.Documents.PhoneCall)
	     And Not AccessRight("Read",Metadata.Documents.IncomingEmail)
	     And Not AccessRight("Read",Metadata.Documents.OutgoingEmail)) Then
		
		Return "";
		
	EndIf;
	
	MatchingRequestsData.Insert("UnprocessedInteractions",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "
	|SELECT DISTINCT ALLOWED
	|	CAST(Meeting.LongDesc AS STRING(1024)) AS LongDesc,
	|	Meeting.Ref AS Ref,
	|	Meeting.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) AS ReviewAfter,
	|	&MeetingLine AS Kind
	|FROM
	|	Document.Meeting.Attendees AS MeetingParticipants
	|		INNER JOIN Document.Meeting AS Meeting
	|		ON MeetingParticipants.Ref = Meeting.Ref
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON Meeting.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	(MeetingParticipants.Contact = &Partner
	|			OR MeetingParticipants.Contact.Owner = &Partner)
	|	AND (NOT Meeting.DeletionMark)
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CAST(PlannedInteraction.LongDesc AS STRING(1024)),
	|	PlannedInteraction.Ref,
	|	PlannedInteraction.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) AS ReviewAfter,
	|	&ScheduledInteractionLine
	|FROM
	|	Document.PlannedInteraction.Attendees AS PlannedInteractionAttendees
	|		INNER JOIN Document.PlannedInteraction AS PlannedInteraction
	|		ON PlannedInteractionAttendees.Ref = PlannedInteraction.Ref
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON PlannedInteractionAttendees.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	(PlannedInteractionAttendees.Contact = &Partner
	|			OR PlannedInteractionAttendees.Contact.Owner = &Partner)
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|	AND (NOT PlannedInteraction.DeletionMark)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CAST(PhoneCall.LongDesc AS STRING(1024)),
	|	PhoneCall.Ref,
	|	PhoneCall.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) AS ReviewAfter,
	|	&StringPhoneCall
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON PhoneCall.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	(NOT PhoneCall.DeletionMark)
	|	AND (PhoneCall.SubscriberContact = &Partner
	|			OR PhoneCall.SubscriberContact.Owner = &Partner)
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CAST(IncomingEmail.Subject AS STRING(1024)),
	|	IncomingEmail.Ref,
	|	IncomingEmail.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) AS ReviewAfter,
	|	&IncomingEmailString
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON IncomingEmail.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	(IncomingEmail.SenderContact = &Partner
	|			OR IncomingEmail.SenderContact.Owner = &Partner)
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|	AND (NOT IncomingEmail.DeletionMark)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CAST(OutgoingEmail.Subject AS STRING(1024)),
	|	OutgoingEmail.Ref,
	|	OutgoingEmail.EmployeeResponsible AS EmployeeResponsible,
	|	ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) AS ReviewAfter,
	|	&OutgoingMessageLine
	|FROM
	|	Document.OutgoingEmail.EmailRecipients AS OutgoingEmailEmailRecipients
	|		INNER JOIN Document.OutgoingEmail AS OutgoingEmail
	|		ON OutgoingEmailEmailRecipients.Ref = OutgoingEmail.Ref
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON OutgoingEmail.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	(NOT OutgoingEmail.DeletionMark)
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|	AND (OutgoingEmailEmailRecipients.Contact = &Partner
	|			OR OutgoingEmailEmailRecipients.Contact.Owner = &Partner)
	|	AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
	|TOTALS
	|	COUNT(DISTINCT Ref)
	|BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";

EndFunction

Function TextOfClientClassificationRequest(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.InformationRegisters.ABCXYZCustomerClassification)
		Or (Not GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit")
		 And Not GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue")
		 And Not GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales")) Then
		
		Return "";
		
	EndIf;
	
	MatchingRequestsData.Insert("ClientClassification",LastPacketNumber + 4);
	LastPacketNumber = LastPacketNumber + 5;
	
	Return "
	|SELECT ALLOWED DISTINCT TOP 2
	|	ABCXYZCustomerClassification.Period AS Period
	|INTO ClassificationPeriods
	|FROM
	|	InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
	|
	|ORDER BY
	|	Period DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ClassificationPeriods.Period) AS MaximumPeriod_,
	|	MIN(ClassificationPeriods.Period) AS MinimumPeriod_
	|INTO MinimumMaximumPeriod
	|FROM
	|	ClassificationPeriods AS ClassificationPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MinimumMaximumPeriod.MaximumPeriod_ AS CurrentPeriod,
	|	CASE
	|		WHEN MinimumMaximumPeriod.MinimumPeriod_ = MinimumMaximumPeriod.MaximumPeriod_
	|			THEN NULL
	|		ELSE MinimumMaximumPeriod.MinimumPeriod_
	|	END AS PreviousPeriod_
	|INTO DefinedClassificationPeriods
	|FROM
	|	MinimumMaximumPeriod AS MinimumMaximumPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ABCXYZCustomerClassification.ClassificationParameterType AS ClassificationParameterType,
	|	CASE
	|		WHEN ABCXYZCustomerClassification.Period = DefinedClassificationPeriods.CurrentPeriod
	|			THEN ""Current_""
	|		ELSE ""Previous""
	|	END AS StringPeriod,
	|	ISNULL(ABCXYZCustomerClassification.ClassificationType, VALUE(Enum.TypesOfClassification.EmptyRef)) AS ClassificationType,
	|	ISNULL(ABCXYZCustomerClassification.Class, UNDEFINED)                                                     AS Class,
	|	ISNULL(ABCXYZCustomerClassification.ClassificationParameterValue, 0)                                       AS ClassificationParameterValue,
	|	ISNULL(ABCXYZCustomerClassification.Period, DATETIME(1, 1, 1))                                              AS Period
	|FROM
	|	DefinedClassificationPeriods AS DefinedClassificationPeriods,
	|	ClassificationPeriods AS ClassificationPeriods
	|		LEFT JOIN InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
	|		ON ClassificationPeriods.Period = ABCXYZCustomerClassification.Period
	|WHERE
	|	ABCXYZCustomerClassification.Partner = &Partner
	|
	|ORDER BY
	|	ClassificationType DESC
	|TOTALS BY
	|	ClassificationParameterType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DefinedClassificationPeriods.CurrentPeriod,
	|	DefinedClassificationPeriods.PreviousPeriod_
	|FROM
	|	DefinedClassificationPeriods AS DefinedClassificationPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function QueryTextAboutPartnerSegments(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.InformationRegisters.SegmentPartners) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("PartnerSegments",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	 Return "SELECT ALLOWED
	 |	PartnersSegments.Description,
	 |	PartnersSegments.EmployeeResponsible,
	 |	PartnersSegments.Ref AS Ref,
	 |	PartnersSegments.LongDesc
	 |FROM
	 |	InformationRegister.SegmentPartners AS SegmentPartners
	 |		INNER JOIN Catalog.PartnersSegments AS PartnersSegments
	 |		ON SegmentPartners.Segment = PartnersSegments.Ref
	 |WHERE
	 |	SegmentPartners.Partner = &Partner
	 |	AND (NOT PartnersSegments.DeletionMark)
	 |TOTALS
	 |	COUNT(DISTINCT Ref)
	 |BY
	 |	OVERALL
	 |;
	 |
	 |////////////////////////////////////////////////////////////////////////////////
	 |";

EndFunction 

Function RequestTextAboutCounterpartyAgreements(MatchingRequestsData,LastPacketNumber)
	
	If Not AccessRight("Read",Metadata.Catalogs.CounterpartyContracts) Then
		Return "";
	EndIf;
	
	MatchingRequestsData.Insert("CounterpartyContracts",LastPacketNumber + 1);
	LastPacketNumber = LastPacketNumber + 1;
	
	Return "SELECT ALLOWED
	|	CounterpartyContracts.Ref AS Ref,
	|	CounterpartyContracts.Description,
	|	CounterpartyContracts.Organization,
	|	CounterpartyContracts.Counterparty,
	|	CASE
	|		WHEN CounterpartyContracts.ValidityEndDate = DATETIME(1, 1, 1)
	|			THEN &StringWithoutRestriction
	|		ELSE CounterpartyContracts.ValidityEndDate
	|	END AS ValidityPeriod
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND CounterpartyContracts.Partner IN
	|			(SELECT
	|				PartnerHierarchy.Parent
	|			FROM
	|				InformationRegister.PartnerHierarchy AS PartnerHierarchy
	|			WHERE
	|				PartnerHierarchy.Partner = &Partner)
	|	
	|	AND (NOT CounterpartyContracts.DeletionMark)
	|TOTALS
	|	COUNT(DISTINCT Ref)
	|BY
	|	OVERALL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function ExecuteBatchOfRequestsForPartner(Partner,MatchingRequestsData)
	
	Query = New Query;
	TemporaryTable = New TempTablesManager;
	LastPacketNumber = 1;
	CurrentDate = EndOfDay(CurrentSessionDate()) + 1;
	
	Query.Text = Query.Text + QueryTextByPartner(MatchingRequestsData);
	Query.Text = Query.Text + RequestTextForPrimaryInterest(MatchingRequestsData,LastPacketNumber);
	If Contacts Then
		
		Query.Text = Query.Text + RequestTextForPartnerContactInformation(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextAboutUpstreamPartners(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextForContactPersons(MatchingRequestsData,LastPacketNumber);
		If Not GetFunctionalOption("UsePartnersAsCounterparties") Then
			Query.Text = Query.Text + RequestTextAboutCounterparties(MatchingRequestsData,LastPacketNumber);
		EndIf;
		
	EndIf;
	
	If ClientData Then
		
		ARAPAccountingServer.CalculateCustomerPaymentDates(TemporaryTable, CurrentDate);
		Query.Text = Query.Text + QueryTextPendingClaims(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + QueryTextTurnovers(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextForAvailableAgreements(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + TextOfRequestAboutCurTransactionsWithClient(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + TextOfRequestForSettlementsWithClient(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextForPartnerOrders(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + TextOfRequestForPartnerRefundRequests(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + TextOfRequestForUnprocessedAcceptanceCertificates(MatchingRequestsData,LastPacketNumber);
		
	EndIf;
	
	If VendorData Then
		
		ARAPAccountingServer.CalculateSupplierPaymentDates(TemporaryTable, CurrentDate);
		Query.Text = Query.Text + TextOfRequestForSettlementsWithSupplier(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextForAgreementsWithSupplier(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextForOrdersToSupplier(MatchingRequestsData,LastPacketNumber);
		
	EndIf;
	
	If ClientData Or VendorData Then
		
		Query.Text = Query.Text + RequestTextAboutCounterpartyAgreements(MatchingRequestsData,LastPacketNumber);
		
	EndIf;
	
	If CurrentActivity Then
		
		Query.Text = Query.Text + TextOfRequestForTransactionsInvolvingPartner(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + TextOfRequestAboutPartnerSParticipationInOtherProjects(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + RequestTextForUnprocessedInteractions(MatchingRequestsData,LastPacketNumber);
		
	EndIf;
	
	If Classification Then
		
		Query.Text = Query.Text + TextOfClientClassificationRequest(MatchingRequestsData,LastPacketNumber);
		Query.Text = Query.Text + QueryTextAboutPartnerSegments(MatchingRequestsData,LastPacketNumber);
		
	EndIf;
	
	CRMLocalization.AddRequestTextToPartnerSDossierReport(ThisObject, Query, MatchingRequestsData, LastPacketNumber);
	
	Query.TempTablesManager = TemporaryTable;
	Query.SetParameter("Partner",Partner);
	Query.SetParameter("NotSpecified",NStr("vi = 'chưa chỉ ra';
											|ru = 'не указан';
											|en = 'not specified'; fa = 'مشخص نشده';
											|it = 'non specificato';
											|pl = 'nie określony';
											|tr = 'belirtilmedi'"));
	Query.SetParameter("CurrentDate",CurrentDate);
	Query.SetParameter("StringMarketingEvent",NStr("vi = 'Hoạt động Marketing';
													|ru = 'Маркетинговые мероприятия';
													|en = 'Marketing activities'; fa = 'فعالیت‌های بازاریابی';
													|it = 'Azioni di marketing';
													|pl = 'Wydarzenia marketingowe';
													|tr = 'Pazarlama faaliyetleri'"));
	Query.SetParameter("ProjectLine",NStr("vi = 'Dự án';
											|ru = 'Проекты';
											|en = 'Projects'; fa = 'پروژه‌ها';
											|it = 'Progetti';
											|pl = 'Projects';
											|tr = 'Projeler'"));
	
	Query.SetParameter("DebtClassificationOption", DebtClassificationOption);
	
	Query.SetParameter("Calendar",Common.ObjectAttributeValue(DebtClassificationOption,"Calendar"));
	Query.SetParameter("StringWithoutRestriction",NStr("vi = 'không giới hạn';
														|ru = 'без ограничения';
														|en = 'without restrictions'; fa = 'بدون محدودیت';
														|it = 'senza restrizioni';
														|pl = 'bez ograniczenia';
														|tr = 'kısıtlamasız'"));
	Query.SetParameter("LineTypical",NStr("vi = 'Chung';
											|ru = 'Типовое';
											|en = 'Standard'; fa = 'استاندارد';
											|it = 'Accordo tipo';
											|pl = 'Typowa';
											|tr = 'Standart'"));
	Query.SetParameter("LineIndividual",NStr("vi = 'Riêng biệt';
											|ru = 'Индивидуальное';
											|en = 'Individual'; fa = 'شخص حقیقی';
											|it = 'Accordi individuali';
											|pl = 'Indywidualna';
											|tr = 'Özelleştirilmiş'"));
	
	UseStandardTermsOfSalesWithCustomers			= GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
	UseCustomerTermsOfSales	= GetFunctionalOption("UseCustomerTermsOfSales");
	ToUseTermsOfSales				= GetFunctionalOption("ToUseTermsOfSales");
	OnlyStandard = UseStandardTermsOfSalesWithCustomers And Not UseCustomerTermsOfSales;
	OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales;
	Query.SetParameter("OnlyStandard", OnlyStandard);
	Query.SetParameter("OnlyPersonal", OnlyPersonal);
	Query.SetParameter("ToUseTermsOfSales", ToUseTermsOfSales);
	
	Query.SetParameter("OutgoingMessageLine",NStr("vi = 'E-mail đi';
													|ru = 'Исходящее письмо';
													|en = 'Outgoing email'; fa = 'ایمیل خروجی';
													|it = 'Messaggio in uscita';
													|pl = 'List wychodzący';
													|tr = 'Giden e-posta'"));
	Query.SetParameter("StringWithoutRestriction",NStr("vi = 'không giới hạn';
														|ru = 'без ограничения';
														|en = 'without restrictions'; fa = 'بدون محدودیت';
														|it = 'senza restrizioni';
														|pl = 'bez ograniczenia';
														|tr = 'kısıtlamasız'"));
	Query.SetParameter("IncomingEmailString",NStr("vi = 'E-mail đến';
													|ru = 'Входящее письмо';
													|en = 'Incoming email'; fa = 'ایمیل ورودی';
													|it = 'E-mail in arrivo';
													|pl = 'Przychodzący list';
													|tr = 'Gelen e-posta'"));
	Query.SetParameter("StringPhoneCall",NStr("vi = 'Cuộc gọi điện thoại';
												|ru = 'Телефонный звонок';
												|en = 'Phone call'; fa = 'تماس تلفنی';
												|it = 'Telefonata';
												|pl = 'Połączenie telefoniczne';
												|tr = 'Telefon görüşmesi'"));
	Query.SetParameter("ScheduledInteractionLine",NStr("vi = 'Giao tiếp dự tính';
														|ru = 'Запланированное взаимодействие';
														|en = 'Scheduled interaction'; fa = 'تعامل برنامه‌ریزی‌شده';
														|it = 'Interazione pianificata';
														|pl = 'Interakcja zaplanowana';
														|tr = 'Programlı etkileşim'"));
	Query.SetParameter("MeetingLine",NStr("vi = 'Cuộc gặp';
											|ru = 'Встреча';
											|en = 'Meeting'; fa = 'Meeting';
											|it = 'Incontro';
											|pl = 'Meeting';
											|tr = 'Randevu'"));
	Query.SetParameter("NotOverdue", NStr("vi = 'Chưa quá hạn';
											|ru = 'Не просрочено';
											|en = 'Not overdue'; fa = 'معوق نشده';
											|it = 'Non scaduto';
											|pl = 'Nie przeterminowano';
											|tr = 'Vadesi geçmemiş'"));
	Query.SetParameter("PaymentsAreIrrelevant", NStr("vi = 'Công nợ chưa thiết thực';
													|ru = 'Расчеты не актуальны';
													|en = 'Calculations are not relevant'; fa = 'Calculations are not relevant';
													|it = 'Calcoli obsoleti';
													|pl = 'Obliczenia nie są aktualne';
													|tr = 'Hesaplamalar güncel değil'"));
	
	Query.SetParameter("NewOnlineARAPAccounting",GetFunctionalOption("NewOnlineARAPAccounting"));
	
	Return Query.ExecuteBatch();
	
EndFunction 

#EndRegion

#Region DataOutput

// LongDesc
// 
// Parameters:
// 	RequestResultForPartnerDetails       - QueryResult - data on the partner's banking details.
// 	RequestResultForAdditionalBankingDetails - QueryResult - data on additional partner details.
// 	QueryResultPrimaryInterest           - QueryResult - data on the primary interest.
// 	ReportTable                              - SpreadsheetDocument - report table.
// 	Template                                      - SpreadsheetDocument - report layout.
//
Procedure OutputPartnerData(RequestResultForPartnerDetails,
	                            RequestResultForAdditionalBankingDetails,
	                            QueryResultPrimaryInterest,
	                            ReportTable,Template)
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	SamplePartnerDetails = RequestResultForPartnerDetails.Select(); // QueryResultSelection
	SamplePartnerDetails.Next();

	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	Area = Template.GetArea("Title");
	Area.Parameters.PartnerName = SamplePartnerDetails.Description;
	Area.Parameters.Partner              = ?(UsePartnersAsCounterparties, NStr("vi = 'Đối tác';
																				|ru = 'Контрагент';
																				|en = 'Counterparty'; fa = 'طرف حساب';
																				|it = 'Controparte';
																				|pl = 'Kontrahent';
																				|tr = 'Cari hesap'"), NStr("vi = 'Bạn hàng';
																											|ru = 'Партнер';
																											|en = 'Partner'; fa = 'شریک تجاری';
																											|it = 'Partner';
																											|pl = 'Partner';
																											|tr = 'İş ortağı'"));
	ReportTable.Put(Area,1);
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,
	                           ReportTable,
	                           ?(UsePartnersAsCounterparties, NStr("vi = 'Dữ liệu của đối tác';
																	|ru = 'Данные контрагента';
																	|en = 'Counterparty data'; fa = 'داده‌های طرف حساب';
																	|it = 'Dati del contraente';
																	|pl = 'Dane kontrahenta';
																	|tr = 'Cari hesap verileri'"), NStr("vi = 'Dữ liệu bạn hàng';
																									|ru = 'Данные партнера';
																									|en = 'Partner data'; fa = 'Partner data';
																									|it = 'Dati partner';
																									|pl = 'Dane partnera';
																									|tr = 'İş ortağı verileri'")));
	
	Area = Template.GetArea("PartnerData");
	ReportTable.StartRowGroup("PartnerData");
	FillPropertyValues(Area.Parameters,SamplePartnerDetails);
	Area.Parameters.RegistrationDate = Format(SamplePartnerDetails.RegistrationDate,"DF=MM/dd/yy");
	Area.Parameters.RelationshipType_ = PartnersAndCounterparties.GenerateStringOfCurRelationshipTypes(SamplePartnerDetails);
	ReportTable.Put(Area,2);
	
	If UsePartnersAsCounterparties Then
		
		Area = Template.GetArea("PartnerCounterpartyData");
		Area.Parameters.LegalEntityIndividual = SamplePartnerDetails.LegalEntityIndividual;
		Area.Parameters.INN_CPP   = SamplePartnerDetails.TIN + 
		                                ?(IsBlankString(SamplePartnerDetails.CRTR),"","\" + SamplePartnerDetails.CRTR);
		ReportTable.Put(Area,2);
		
	EndIf;
	
	If GetFunctionalOption("UseBusinessRegions") Then
		Area = Template.GetArea("PartnerDataBusinessRegion");
		Area.Parameters.BusinessRegion = SamplePartnerDetails.BusinessRegion;
		ReportTable.Put(Area,2);
	EndIf;
	
	If QueryResultPrimaryInterest <> Undefined And Not QueryResultPrimaryInterest.IsEmpty() Then
		
		SamplingPrimaryInterest = QueryResultPrimaryInterest.Select();
		SamplingPrimaryInterest.Next();
		
		Area = Template.GetArea("PrimaryInterest");
		FillPropertyValues(Area.Parameters,SamplingPrimaryInterest);
		ReportTable.Put(Area,2);
		
	EndIf;
	
	SampleAdditionalInformation = RequestResultForAdditionalBankingDetails.Select();
	While SampleAdditionalInformation.Next() Do
	
		Area = Template.GetArea("PartnerDataAdditionalBankingDetails");
		FillPropertyValues(Area.Parameters,SampleAdditionalInformation);
		ReportTable.Put(Area,2);
	
	EndDo;
	
	DisplayTextArea(Template,ReportTable,NStr("vi = 'Diễn giải:';
												|ru = 'Комментарий:';
												|en = 'Comment:'; fa = 'توضیحات:';
												|it = 'Commento:';
												|pl = 'Comment:';
												|tr = 'Yorum:'"),SamplePartnerDetails.Comment);
	DisplayTextArea(Template,ReportTable,NStr("vi = 'Thông tin bổ sung:';
												|ru = 'Дополнительная информация:';
												|en = 'Additional information:'; fa = 'Additional information:';
												|it = 'Informazione aggiuntiva:';
												|pl = 'Informacje dodatkowe:';
												|tr = 'Ek bilgi:'"),SamplePartnerDetails.AdditionalInformation);
	
	ReportTable.EndRowGroup();
	
EndProcedure

// Displays the text area in the report.
// 
// Parameters:
// 	Template         - SpreadsheetDocument - report layout.
// 	ReportTable - SpreadsheetDocument - report table.
// 	Title     - String            - the header region.
// 	Text         - String            - text output to the area.
Procedure DisplayTextArea(Template,ReportTable,Title,Text)

	If IsBlankString(Text) Then
		Return;
	EndIf;
	
	Area = Template.GetArea("TextTitle_");
	Area.Parameters.Title = Title;
	ReportTable.Put(Area);
	
	Area = Template.GetArea("TextContent_");
	Area.Parameters.Text = Text;
	ReportTable.Put(Area);

EndProcedure

Procedure DisplayDataAboutPartnerSContactInformation(RequestResultForPartnerSContactInformation,ReportTable,Template)

	If RequestResultForPartnerSContactInformation.IsEmpty() Then
		Return;
	EndIf;
	
	SelectingPartner_KIDS =  RequestResultForPartnerSContactInformation.Select();
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,ReportTable,NStr("vi = 'Thông tin liên hệ';
													|ru = 'Контактная информация';
													|en = 'Contact details'; fa = 'اطلاعات تماس';
													|it = 'Informazioni di contatto';
													|pl = 'Dane kontaktowe';
													|tr = 'İletişim bilgileri'"));
	ReportTable.StartRowGroup("ContactInformation");
	While SelectingPartner_KIDS.Next() Do
	
		Area = Template.GetArea("ContactInformation");
		FillPropertyValues(Area.Parameters,SelectingPartner_KIDS);
		ReportTable.Put(Area,2);
	
	EndDo;
	
	ReportTable.EndRowGroup();

EndProcedure

Procedure DisplayDataAboutUpstreamPartners(RequestResultForUpstreamPartners,ReportTable,Template)

	If RequestResultForUpstreamPartners.IsEmpty() Then
		Return;
	EndIf;
	
	SampleResults = RequestResultForUpstreamPartners.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,
	                           ReportTable,
	                           StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Bạn hàng lớp trên - %1.';
																							|ru = 'Вышестоящие партнеры - %1.';
																							|en = 'Upstream partners - %1.'; fa = 'Upstream partners - %1.';
																							|it = 'Partner superiori - %1.';
																							|pl = 'Partnerzy nadrzędne - %1.';
																							|tr = 'Yukarıdaki iş ortakları - %1.'"),
	                                                                                        SampleResults.Ref));
	
	DetailsSelection = SampleResults.Select();
	ReportTable.StartRowGroup("SuperiorPartners");
	OutputAreaWithoutParameters("HeadPartnerCap",Template,ReportTable);
	EvenString = False;
	While DetailsSelection.Next() Do
		
		Area = Template.GetArea("HeadPartnerString");
		FillPropertyValues(Area.Parameters,DetailsSelection);
		Area.Parameters.ContactInformationPresentation = MultiLinePresentationOfContactInformation(DetailsSelection.ContactInformation.Unload());
		If EvenString Then
			AreaTableRow          = Area.Areas.TableRowUpstreamPartners; // SpreadsheetDocumentRange
			AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();

EndProcedure

Procedure DisplayInformationAboutContactPersons(RequestResultForContactPersons,ReportTable,Template)

	If RequestResultForContactPersons.IsEmpty() Then
		Return;
	EndIf;
	
	SampleResults = RequestResultForContactPersons.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();

	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,
	                           ReportTable,
	                           StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Người liên hệ - %1';
																							|ru = 'Контактные лица - %1';
																							|en = 'Contact persons - %1'; fa = 'Contact persons - %1';
																							|it = 'Persone di contatto - %1';
																							|pl = 'Osoby kontaktowe - %1';
																							|tr = 'İrtibat kişileri - %1'"),
	                                                                                   SampleResults.Ref));
	
	ReportTable.StartRowGroup("ContactPersons");
	OutputAreaWithoutParameters("ContactPersonHeader",Template,ReportTable);
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea("ContactPersonString");
		FillPropertyValues(Area.Parameters,DetailsSelection);
		Area.Parameters.RolePresentation = MultiLinePresentationOfContactPersonRoles(DetailsSelection.ContactPersonRoles);
		Area.Parameters.ContactInformationPresentation = MultiLinePresentationOfContactInformation(DetailsSelection.ContactInformation.Unload());
		If EvenString Then
			AreaTableRow = Area.Areas.RowOfContactPersonsTable; // SpreadsheetDocumentRange 
			AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();

EndProcedure

Procedure DisplayDataAboutCounterparties(RequestResultForCounterparties,ReportTable,Template)
	
	If RequestResultForCounterparties.IsEmpty() Then
		Return;
	EndIf;
	
	ContactInformationTable1 = New ValueTable;
	ContactInformationTable1.Columns.Add("Kind");
	ContactInformationTable1.Columns.Add("Presentation");
	
	CounterpartySelection = RequestResultForCounterparties.Select(QueryResultIteration.ByGroups);
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,
	                           ReportTable,
	                           StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối tác - %1.';
																							|ru = 'Контрагенты - %1.';
																							|en = 'Counterparties - %1.'; fa = 'Counterparties - %1.';
																							|it = 'Contraenti - %1.';
																							|pl = 'Kontrahenci - %1.';
																							|tr = 'Cari hesaplar - %1.'"),
	                                                                                   CounterpartySelection.Count()));
	ReportTable.StartRowGroup("Counterparties");
	OutputAreaWithoutParameters("CounterpartiesHeader",Template,ReportTable);
	
	EvenString = False;
	
	While CounterpartySelection.Next() Do
	
		Area = Template.GetArea("CounterpartiesLine");
		FillPropertyValues(Area.Parameters, CounterpartySelection);
		Area.Parameters.INN_CPP = CounterpartySelection.TIN + ?(IsBlankString(CounterpartySelection.CRTR),"","\" + CounterpartySelection.CRTR);
		
		ContactInformationTable1.Clear();
		
		DetailsSelection = CounterpartySelection.Select();
		While DetailsSelection.Next() Do
			
			NewRow = ContactInformationTable1.Add();
			FillPropertyValues(NewRow, DetailsSelection);
			
		EndDo;
		
		Area.Parameters.ContactInformationPresentation = MultiLinePresentationOfContactInformation(ContactInformationTable1);
		
		If EvenString Then
			ReportLineArea = Area.Areas.RowOfCounterpartiesTable; // SpreadsheetDocumentRange
			ReportLineArea.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		
		ReportTable.Put(Area,2);
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataOnCurTransactionsWithClient(QueryResultForCurTransactionsWithPartner,ReportTable,Template)
	
	If QueryResultForCurTransactionsWithPartner.IsEmpty() Then
		Return;
	EndIf;
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	SampleResults = QueryResultForCurTransactionsWithPartner.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong các giao dịch - %1, có khả năng là số tiền %2%3.';
																				|ru = 'В работе сделок - %1, потенциально на сумму %2 %3.';
																				|en = 'Sales opportunities in progress - %1, with total potential amount of %2 %3.'; fa = 'Sales opportunities in progress - %1, with total potential amount of %2 %3.';
																				|it = 'Transazioni in lavorazione - %1, per l''importo potenziale di %2 %3.';
																				|pl = 'W pracy transakcji - %1, potencjalnie w kwocie %2 %3.';
																				|tr = 'Potansiyel olarak %2 %3 tutarında satış fırsatı işleminde - %1'"),
	                                                                         SampleResults.Ref,
	                                                                         SampleResults.PotentialSaleAmount,
	                                                                         SampleResults.Currency);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	ReportTable.StartRowGroup("CurTransactions_");
	OutputAreaWithoutParameters("CurTransactionsCap",Template,ReportTable);
	EvenString = False;
	TransactionSelection_1 = SampleResults.Select();
	While TransactionSelection_1.Next() Do
		
		Area = Template.GetArea("CurLineTransactions");
		FillPropertyValues(Area.Parameters,TransactionSelection_1);
		If EvenString Then
			TableRowCurTransactions = Area.Areas.TableRowCurTransactions; //  SpreadsheetDocumentRange
			TableRowCurTransactions.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure



// Displays information about the partner's participation in other projects in the report
// 
// Parameters:
// 	RequestResultTotals  - QueryResult - contains summary data.
// 	DetailsRequestResult - QueryResult - contains detailed data.
// 	ReportTable          - SpreadsheetDocument - report table.
// 	Template                  - SpreadsheetDocument - report layout.
//
Procedure DisplayDataOnPartnerSParticipationInOtherProjects(RequestResultTotals, DetailsRequestResult, ReportTable, Template)
	
	If RequestResultTotals.IsEmpty() Then
		Return;
	EndIf;
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	SampleResults = RequestResultTotals.Select();
	
	TitleText = NStr("vi = 'Tham gia trong';
					|ru = 'Участвует в';
					|en = 'Participates in'; fa = 'Participates in';
					|it = 'Partecipa a';
					|pl = 'Bierze udział w';
					|tr = 'Katılıyor'") + " ";
	
	While SampleResults.Next() Do
		TitleText = TitleText + SampleResults.Kind + " - " + SampleResults.Count + ", ";
	EndDo;
	
	TitleText = Left(TitleText,StrLen(TitleText)-2) + ".";
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	ReportTable.StartRowGroup("OtherProjects");
	OutputAreaWithoutParameters("OtherProjectsHeader",Template,ReportTable);
	SelectionKind = DetailsRequestResult.Select(QueryResultIteration.ByGroups);
	While SelectionKind.Next() Do
		Area = Template.GetArea("Group");
		Area.Parameters.GroupName = SelectionKind.Kind;
		ReportTable.Put(Area,2);
		ReportTable.StartRowGroup("OtherProjectsView");
		
		EvenString = False;
		SampleProject = SelectionKind.Select(QueryResultIteration.ByGroups);
		While SampleProject.Next() Do
			
			Area = Template.GetArea("OtherProjectsLine");
			DetailsSelection = SampleProject.Select();
			Area.Parameters.ProjectRoles = PartnerRoleStringInTransaction(DetailsSelection);
			Area.Parameters.ContactPersonsRoles = RoleStringOfContactPersonsInTransaction(DetailsSelection);
			DetailsSelection.Next();
			FillPropertyValues(Area.Parameters, DetailsSelection);
			If EvenString Then
				AreaTableRow = Area.Areas.TableRowOtherProjects; // SpreadsheetDocumentRange
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			EndIf;
			ReportTable.Put(Area,3);
			
			EvenString = Not EvenString;
			
		EndDo;
		
		ReportTable.EndRowGroup();
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayTheseRevolutions(RequestResultRevolutions, ReportTable, Template);

	If RequestResultRevolutions.IsEmpty() Then
		Return;
	EndIf;
	
	SampleResults =  RequestResultRevolutions.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tổng doanh thu từ bán hàng cho khách hàng - %1 %2.';
																				|ru = 'Общий объем выручки от продаж клиенту - %1 %2.';
																				|en = 'Total sales revenue to customer - %1 %2.'; fa = 'Total sales revenue to customer - %1 %2.';
																				|it = 'Ricavo totale dalle vendite al cliente - %1 %2.';
																				|pl = 'Całkowite przychody ze sprzedaży klientowi - %1 %2.';
																				|tr = 'Mişteriye satışlardan elde edilen toplam gelir - %1 %2.'"),
	                                                                         Format(SampleResults.RevenueAmountTurnover, "NFD=2"),
	                                                                         SampleResults.Currency);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	ReportTable.StartRowGroup("Turnovers");
	OutputAreaWithoutParameters("TurnoverCap",Template,ReportTable);
	
	SalesPreviousPeriod = 0;
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea("StringRevolutions");
		FillPropertyValues(Area.Parameters,DetailsSelection);
		
		SalesCurPeriod = DetailsSelection.RevenueAmountTurnover;
		If SalesPreviousPeriod <> 0 And SalesCurPeriod <> 0 And SalesCurPeriod <> SalesPreviousPeriod Then
			If SalesPreviousPeriod > SalesCurPeriod Then
				Update = Round( - ((1 - SalesCurPeriod / SalesPreviousPeriod) * 100) ,2);
				ReportLineArea = Area.Areas.Update; // SpreadsheetDocumentRange
				ReportLineArea.TextColor = StyleColors.NegativeTextColor;
			Else
				Update = Round((SalesCurPeriod / SalesPreviousPeriod - 1) * 100,2);
			EndIf;
			Area.Parameters.Update = Update;
		EndIf;
		
		SalesPreviousPeriod = DetailsSelection.RevenueAmountTurnover;
		If EvenString Then
			ReportLineArea = Area.Areas.TableRowRevolutions; // SpreadsheetDocumentRange
			ReportLineArea.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();

EndProcedure 

Procedure DisplayDataAboutAvailableAgreements(RequestResultForAgreements,ReportTable, Template)
	
	If RequestResultForAgreements.IsEmpty() Then
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	
	SampleResults = RequestResultForAgreements.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Có sẵn thỏa thuận với khách hàng - %1.';
																				|ru = 'Доступно соглашений с клиентом - %1.';
																				|en = 'Available terms of sales - %1.'; fa = 'Available terms of sales - %1.';
																				|it = 'Accordi con il cliente disponibili - %1.';
																				|pl = 'Dostępnych umów z klientem - %1';
																				|tr = 'İstemciyle sözleşme mevcuttur- %1.'"),SampleResults.Ref);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	// The output table
	ReportTable.StartRowGroup("CustomersTermsOfSales");
	OutputAreaWithoutParameters("AgreementsWithClientHeader",Template,ReportTable);
	
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea("AgreementsWithClientString");
		FillPropertyValues(Area.Parameters, DetailsSelection);
		If EvenString Then
			AreaTableRow           = Area.Areas.CustomerAgreementTableRow; // SpreadsheetDocumentRange
			AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayInformationAboutAgreementsWithSupplier(RequestResultForAgreements,ReportTable, Template)
	
	If RequestResultForAgreements.IsEmpty() Then
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	
	SampleResults = RequestResultForAgreements.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Có thỏa thuận với nhà cung cấp - %1.';
																				|ru = 'Доступно соглашений с поставщиком - %1.';
																				|en = 'Available terms of purchase - %1.'; fa = 'Available terms of purchase - %1.';
																				|it = 'Accordi con il fornitore disponibili - %1.';
																				|pl = 'Dostępnych umów z dostawcem - %1.';
																				|tr = 'Tedarikçiyle sözleşme mevcuttur- %1.'"),
	                                                                         SampleResults.Ref);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	// The output table
	ReportTable.StartRowGroup("TermsOfPurchase");
	OutputAreaWithoutParameters("AgreementsWithHeaderSupplier",Template,ReportTable);
	
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea("AgreementsWithServiceProvider");
		FillPropertyValues(Area.Parameters, DetailsSelection);
		If EvenString Then
			AreaTableRow = Area.Areas.RowOfSupplierAgreementTable; // SpreadsheetDocumentRange 
			AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure OutputDataOnUnprocessedInteractions(QueryResultForInteractions,ReportTable, Template)
	
	If QueryResultForInteractions.IsEmpty() Then
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	SampleResults = QueryResultForInteractions.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Giao tiếp chưa xử lý - %1';
																				|ru = 'Неотработанных взаимодействий - %1';
																				|en = 'Unprocessed interactions - %1'; fa = 'Unprocessed interactions - %1';
																				|it = 'Interazioni non elaborati - %1';
																				|pl = 'Nieprzetworzonych interakcji - %1';
																				|tr = 'İşlenmemiş etkileşimler - %1'"),
	                                                                         SampleResults.Ref);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	// The output table
	ReportTable.StartRowGroup("UnprocessedInteractions");
	OutputAreaWithoutParameters("UnprocessedInteractionsHeader",Template,ReportTable);
	
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea("UnprocessedInteractionsString");
		FillPropertyValues(Area.Parameters, DetailsSelection);
		If EvenString Then
			ReportLineArea = Area.Areas.TableRowUnprocessedInteractions; // SpreadsheetDocumentRange
			ReportLineArea.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

// Displays information about transactions involving the partner
// 
// Parameters:
// 	RequestResultTotals  - QueryResult - summary of transactions.
// 	DetailsRequestResult - QueryResult - detailed information about transactions.
// 	ReportTable          - SpreadsheetDocument - report table.
// 	Template                  - SpreadsheetDocument - report layout.
//
Procedure DisplayDataOnTransactionsInvolvingPartner(RequestResultTotals,DetailsRequestResult,ReportTable, Template)
	
	If DetailsRequestResult.IsEmpty() Then
		Return;
	EndIf;
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	SampleResults = RequestResultTotals.Select(); 
	SampleResults.Next();
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tham gia trong %1 vụ việc, với tổng số tiền là %2 %3.';
																				|ru = 'Участвует в сделках - %1, потенциально на сумму %2 %3.';
																				|en = 'Participates in sales opportunities - %1, with total potential amount of %2 %3.'; fa = 'Participates in sales opportunities - %1, with total potential amount of %2 %3.';
																				|it = 'Partecipa alle transazioni - %1, per l''importo potenziale di %2 %3.';
																				|pl = 'Uczestniczy w umowach - %1, potencjalnie na kwotę %2 %3.';
																				|tr = 'Potasniyel olarak %2 %3 tutarında, satış fırsatlarına katılıyor - %1'"),
	                                                                         SampleResults.TransactionNumber,
	                                                                         SampleResults.PotentialSaleAmount,
	                                                                         SampleResults.Currency);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	ReportTable.StartRowGroup("ParticipationInSalesOpportunities");
	OutputAreaWithoutParameters("ParticipationInTransactionsHeader",Template,ReportTable);
	
	EvenString = False;
	SampleTransactionDetails = DetailsRequestResult.Select(QueryResultIteration.ByGroups);
	While SampleTransactionDetails.Next() Do
		DetailSamplingIsStageOfProcess = SampleTransactionDetails.Select(QueryResultIteration.ByGroups);
		DetailSamplingIsStageOfProcess.Next();
	
		Area = Template.GetArea("ParticipationInTransactionsString");
		FillPropertyValues(Area.Parameters,DetailSamplingIsStageOfProcess);
		SelectingRoleDetails = DetailSamplingIsStageOfProcess.Select();
		Area.Parameters.RolesInSalesOpportunity = PartnerRoleStringInTransaction(SelectingRoleDetails);
		Area.Parameters.ContactPersonsRoles = RoleStringOfContactPersonsInTransaction(SelectingRoleDetails);
		If EvenString Then
			ReportLineArea = Area.Areas.RowOfTableParticipationInTransactions; // SpreadsheetDocumentRange
			ReportLineArea.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataAboutPartnerOrders(RequestResultForOrders,ReportTable, Template,TypeOfOrders)
	
	If RequestResultForOrders.IsEmpty() Then
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	
	SampleResults = RequestResultForOrders.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	TotalOrders = SampleResults.Ref;
	
	If TypeOfOrders = "ReturnRequest" Then
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đang làm việc với giấy đề nghị trả hàng từ người mua - %1';
																					|ru = 'В работе заявок на возврат от клиента - %1';
																					|en = 'Return requests from the customer in progress - %1'; fa = 'Return requests from the customer in progress - %1';
																					|it = 'Richieste di reso dal cliente in lavorazione - %1';
																					|pl = 'W pracy wniosków o zwrot od klienta - %1';
																					|tr = 'İstemciden gelen iade başvuruları işlemlerinde - %1'"),
		                                                                         TotalOrders);
	Else
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Các đơn hàng đang làm việc %1 - %2';
																					|ru = 'В работе заказов %1 - %2';
																					|en = 'The %1 - %2 orders are in progress'; fa = 'The %1 - %2 orders are in progress';
																					|it = 'Ordini in lavorazione %1 - %2';
																					|pl = 'W pracy zamówień %1 - %2';
																					|tr = 'Sipariş işleminde %1 - %2'"),
		                                                                         TypeOfOrders,TotalOrders);
	EndIf; 
	
	FirstCurrency = True;
	CurrencySelection1 = SampleResults.Select(QueryResultIteration.ByGroups);
	While CurrencySelection1.Next() Do
		
		If CurrencySelection1.Ref = TotalOrders Then
			TitleText = TitleText + " " +
			                 StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'với số tiền %1 %2,';
																							|ru = 'на сумму %1 %2,';
																							|en = 'in the amount of %1 %2,'; fa = 'in the amount of %1 %2,';
																							|it = 'importo %1 %2,';
																							|pl = 'na kwotę %1 %2,';
																							|tr = '%1 %2 tutarında,'") + " ",
			                                                                              Format(CurrencySelection1.DocumentAmount, "NFD=2"),
			                                                                              CurrencySelection1.Currency);
		Else
			ReplacementText = " " + ?(TypeOfOrders = "ReturnRequest", 
			                NStr("vi = '%1 giấy đề nghị hoàn lại tiền từ khách hàng với số tiền %2%3,';
								|ru = '%1 заявка на возврат от клиента на сумму %2 %3,';
								|en = '%1 return request from customer in the amount of %2 %3,'; fa = '%1 return request from customer in the amount of %2 %3,';
								|it = '%1 richiesta di reso dal cliente per un importo di %2 %3,';
								|pl = '%1 wniosków o zwrot od klienta na kwotę %2 %3,';
								|tr = '%2 %3 tutarında müşteriden gelen iade başvurusu %1'") + " ", 
			                NStr("vi = '%1 đơn hàng với số tiền %2%3,';
								|ru = '%1 заказ на сумму %2 %3,';
								|en = '%1 order in the amount of %2 %3,'; fa = '%1 order in the amount of %2 %3,';
								|it = '%1 richiesta per un importo di %2 %3,';
								|pl = '%1 zamówień na kwotę %2 %3,';
								|tr = '%2 %3 tutarında sipariş %1,'") + " ");
			If CurrencySelection1.Ref > 1 And CurrencySelection1.Ref < 5 Then
				ReplacementText = StrReplace(ReplacementText, NStr("vi = 'giấy đề nghị';
																	|ru = 'заявка';
																	|en = 'application'; fa = 'application';
																	|it = 'richiesta';
																	|pl = 'zgłoszenie';
																	|tr = 'Başvuru'"), NStr("vi = 'giấy đề nghị';
																								|ru = 'заявок';
																								|en = 'requests'; fa = 'requests';
																								|it = 'richieste';
																								|pl = 'zgłoszeń';
																								|tr = 'başvuruların'"));
				ReplacementText = StrReplace(ReplacementText, NStr("vi = 'đơn hàng';
																	|ru = 'заказа';
																	|en = 'order'; fa = 'order';
																	|it = 'dell''ordine';
																	|pl = 'zamówienia';
																	|tr = 'siparişin'"), NStr("vi = 'đơn hàng';
																						|ru = 'заказа';
																						|en = 'order'; fa = 'order';
																						|it = 'dell''ordine';
																						|pl = 'zamówienia';
																						|tr = 'siparişin'"));
			ElsIf CurrencySelection1.Ref > 4 Then
				ReplacementText = StrReplace(ReplacementText, NStr("vi = 'giấy đề nghị';
																	|ru = 'заявка';
																	|en = 'application'; fa = 'application';
																	|it = 'richiesta';
																	|pl = 'zgłoszenie';
																	|tr = 'Başvuru'"), NStr("vi = 'giấy đề nghị';
																								|ru = 'заявок';
																								|en = 'requests'; fa = 'requests';
																								|it = 'richieste';
																								|pl = 'zgłoszeń';
																								|tr = 'başvuruların'"));
				ReplacementText = StrReplace(ReplacementText, NStr("vi = 'đơn hàng';
																	|ru = 'заказа';
																	|en = 'order'; fa = 'order';
																	|it = 'dell''ordine';
																	|pl = 'zamówienia';
																	|tr = 'siparişin'"), NStr("vi = 'đơn hàng';
																						|ru = 'заказов';
																						|en = 'orders'; fa = 'orders';
																						|it = 'degli ordini';
																						|pl = 'zamówień';
																						|tr = 'siparişlerin'"));
			EndIf;
			TitleText =  TitleText + ?(FirstCurrency,", " +NStr("vi = 'trong đó';
																|ru = 'в том числе';
																|en = 'including'; fa = 'شامل';
																|it = 'inclusi';
																|pl = 'w tym';
																|tr = 'aynı zamanda'") + " ","")
			                                     + StringFunctionsClientServer.SubstituteParametersToString(ReplacementText,
			                                     CurrencySelection1.Ref,
			                                     Format(CurrencySelection1.DocumentAmount, "NFD=2"),
			                                     CurrencySelection1.Currency);
			FirstCurrency =  False;
		EndIf;
	
	EndDo;
	
	TitleText = Left(TitleText,StrLen(TitleText)-2) + ".";
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	// The output table
	ReportTable.StartRowGroup("SalesOrders");
	OutputAreaWithoutParameters("CustomerOrdersHeader",Template,ReportTable);
	
	EvenString = False;
	CurrencySelection1.Reset();
	While CurrencySelection1.Next() Do
		DetailsSelection = CurrencySelection1.Select(); // QueryResultSelection
		While DetailsSelection.Next() Do
		
			Area = Template.GetArea("CustomerOrdersString");
			FillPropertyValues(Area.Parameters,DetailsSelection);
			Area.Parameters.NumberDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số %1 ngày %2';
																										|ru = '№ %1 от %2';
																										|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
																										|it = '№ %1 da %2';
																										|pl = 'Nr %1 z dnia %2';
																										|tr = '%2 itibaren № %1'"),
			                                                                                      DetailsSelection.Number,
			                                                                                      DetailsSelection.Date);
			If DetailsSelection.Overdue Then
				AreaTableRow            = Area.Areas.CustomerOrdersStatusLine; // SpreadsheetDocumentRange
				AreaTableRow.TextColor = StyleColors.OverdueDataColor;
			EndIf;
			If EvenString Then
				AreaTableRow            = Area.Areas.TableRow; // SpreadsheetDocumentRange
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			EndIf;
			ReportTable.Put(Area,2);
			
			EvenString = Not EvenString;
		
		EndDo;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataUnprocessedReportsOfDiscrepanciesAfterShipment(ResultOfRequestForReportsOfDiscrepanciesAfterShipment,ReportTable,Template) 

	If ResultOfRequestForReportsOfDiscrepanciesAfterShipment.IsEmpty() Then
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	
	NumberOfActs_ = 0;
	FirstCurrency = True;
	TextByCurrency = "";

	SampleResults = ResultOfRequestForReportsOfDiscrepanciesAfterShipment.Select(QueryResultIteration.ByGroups);
	While SampleResults.Next() Do
		If SampleResults.Count() = 1 Then
			TextByCurrency = TextByCurrency + StringFunctionsClientServer.SubstituteParametersToString(
			                 " " + NStr("vi = 'hàng thừa với số tiền %1 %3, hàng thiếu với số tiền %2 %3';
										|ru = 'излишки на сумму %1 %3, недостачи на сумму %2 %3';
										|en = 'surpluses in the amount of %1 %3, shortages in the amount of %2 %3'; fa = 'surpluses in the amount of %1 %3, shortages in the amount of %2 %3';
										|it = 'eccessi per un importo di %1 %3, ammanchi per un importo di %2 %3';
										|pl = 'nadmiary na kwotę %1 %3, niedobory na kwotę %2 %3';
										|tr = '%1 %3 tutarında fazlalıklar, %2 %3 tutarında eksiklikler'") +", ",
			                 Format(SampleResults.Surpluses, "NFD=2"),
			                 Format(SampleResults.Shortages, "NFD=2"),
			                 SampleResults.Currency);
		Else
			TextByCurrency =  TextByCurrency + ?(FirstCurrency,", " + NStr("vi = 'trong đó:';
																			|ru = 'в том числе:';
																			|en = 'including:'; fa = 'including:';
																			|it = 'incluso:';
																			|pl = 'w tym:';
																			|tr = 'aynı zamanda:'"),"") + Chars.LF
			                                     + StringFunctionsClientServer.SubstituteParametersToString(" " + NStr(
			                                     "vi = '%1 (%2)- thừa với số tiền %3 , thiếu với số tiền %4';
												|ru = '%1 (%2)- излишки на сумму %3 , недостачи на сумму %4';
												|en = '%1 (%2) - surpluses in the amount of %3, shortages in the amount of %4'; fa = '%1 (%2) - surpluses in the amount of %3, shortages in the amount of %4';
												|it = '%1 (%2) - eccessi per un importo di %3, ammanchi per un importo di %4';
												|pl = '%1 (%2)- nadmiary na kwotę %3 , niedobory na kwotę %4';
												|tr = '%1 (%2)- %3 tutarında fazlalıklar, %4 tutarında eksiklikler'") +", ",
			                                     SampleResults.Ref,
			                                     SampleResults.Currency,
			                                     Format(SampleResults.Surpluses,   "NFD=2"),
			                                     Format(SampleResults.Shortages, "NFD=2"));
			FirstCurrency =  False;
		EndIf;
		NumberOfActs_ = NumberOfActs_ + SampleResults.Ref;
	EndDo;
	
	TextByCurrency = Left(TextByCurrency,StrLen(TextByCurrency)-2) + ".";
	TitleText = NStr("vi = 'Biên bản tiếp nhận của khách hàng chưa xử lý';
					|ru = 'Неотработанных актов приемки клиента';
					|en = 'Unprocessed customer receiving notes'; fa = 'Unprocessed customer receiving notes';
					|it = 'Atti di accettazione del cliente non elaborati';
					|pl = 'Niespełnionych aktów odbioru klienta';
					|tr = 'İşlenmemiş müşteri kabul tutanakları'") + " - "+ NumberOfActs_ + TextByCurrency;
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	// The output table
	ReportTable.StartRowGroup("ReportsOfDiscrepanciesAfterShipment");
	OutputAreaWithoutParameters("ReportsOfDiscrepanciesAfterShipmentHeader",Template,ReportTable);
	
	EvenString = False;
	SampleResults.Reset();
	While SampleResults.Next() Do
		DetailsSelection = SampleResults.Select();
		While DetailsSelection.Next() Do
			Area = Template.GetArea("ReportsOfDiscrepanciesAfterShipmentRow");
			FillPropertyValues(Area.Parameters,DetailsSelection);
			Area.Parameters.NumberDate = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Số %1 ngày %2';
																										|ru = '№ %1 от %2';
																										|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
																										|it = '№ %1 da %2';
																										|pl = 'Nr %1 z dnia %2';
																										|tr = '%2 itibaren № %1'"),
			                                                                                      DetailsSelection.Number, 
			                                                                                      DetailsSelection.Date);
			If EvenString Then
				AreaTableRow          = Area.Areas.RowOfReportOfDiscrepanciesAfterShipmentTable; // SpreadsheetDocumentRange 
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			EndIf;
			ReportTable.Put(Area,2);
			
			EvenString = Not EvenString;
		EndDo;
	EndDo;
	
	
	ReportTable.EndRowGroup();

EndProcedure

Procedure OutputDataIncompleteClaims(RequestResultPendingClaims,ReportTable, Template)
	
	If RequestResultPendingClaims.IsEmpty() Then
		Return;
	EndIf;

	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	
	SampleResults = RequestResultPendingClaims.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Khiếu nại chưa giải quyết - %1.';
																				|ru = 'Незавершенных претензий - %1.';
																				|en = 'Uncompleted complaints - %1.'; fa = 'Uncompleted complaints - %1.';
																				|it = 'Reclami non completati - %1.';
																				|pl = 'Niedokończonych roszczeń - %1.';
																				|tr = 'Tamamlanmayan talepler - %1.'"),
	                                                                         SampleResults.Ref);
	PrintSubsectionTitle(Template,ReportTable,TitleText,StyleColors.OverdueDataColor);
	
	ReportTable.StartRowGroup("PendingClaims");
	OutputAreaWithoutParameters("IncompleteClaimsHeader",Template,ReportTable);
	
	EvenString = False;
	DetailsSelection = SampleResults.Select(QueryResultIteration.ByGroups);
	While DetailsSelection.Next() Do
		
		Area = Template.GetArea("UnfinishedClaimsLine");
		FillPropertyValues(Area.Parameters,DetailsSelection);
		
		If EvenString Then
			ReportLineArea = Area.Areas.LinePendingClaims; // SpreadsheetDocumentRange
			ReportLineArea.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataOnSettlementsWithClient(ResultOfRequestForSettlements,ReportTable, Template)
	
	If ResultOfRequestForSettlements.IsEmpty() Then 
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	TitleText = NStr("vi = 'Công nợ của khách hàng';
					|ru = 'Задолженность как клиента';
					|en = 'Debt as a customer'; fa = 'Debt as a customer';
					|it = 'Debito come cliente';
					|pl = 'Zadłużenie jako klienta';
					|tr = 'İstemci alacakları/borçları'") + " ";
	CurrencySelection1 = ResultOfRequestForSettlements.Select(QueryResultIteration.ByGroups);
	
	CustomerDebtLine_ = "";
	OverdueDebtLine = "";
	ThisIsOurDuty = "";
	
	While CurrencySelection1.Next() Do
		
		CustomerAccountsReceivable =  CurrencySelection1.CustomerAccountsReceivable - CurrencySelection1.AccountsPayableOfCompany;
		
		If CustomerAccountsReceivable > 0 Then
			CustomerDebtLine_ = CustomerDebtLine_ + Format(CustomerAccountsReceivable,"NFD=2") + " " + CurrencySelection1.Currency + ", ";
		Else
			ThisIsOurDuty = ThisIsOurDuty + Format(-CustomerAccountsReceivable,"NFD=2") + " " + CurrencySelection1.Currency + ", ";
		EndIf;
		If CurrencySelection1.OverdueCustomerDebt <> 0 Then
			OverdueDebtLine = OverdueDebtLine
			                                  + Format(CurrencySelection1.OverdueCustomerDebt,"NFD=2") 
			                                  + " " + CurrencySelection1.Currency + ", ";
		EndIf;
		
	EndDo;
	
	TextCustomerDebt = "";
	If Not IsBlankString(CustomerDebtLine_) Then
		TextCustomerDebt = NStr("vi = 'Tổng nợ phải thu khách hàng';
								|ru = 'Общая задолженность как клиента';
								|en = 'Total debt as a customer'; fa = 'Total debt as a customer';
								|it = 'Debito totale come cliente';
								|pl = 'Ogólne zadłużenie jako klienta';
								|tr = 'İstemcinin toplam alacakları/borçları'") + " " + Left(CustomerDebtLine_,StrLen(CustomerDebtLine_)-2) + ".";
	EndIf;
	
	If Not IsBlankString(ThisIsOurDuty) Then
		TextCustomerDebt = TextCustomerDebt + ?(IsBlankString(TextCustomerDebt), "", Chars.LF)
		                                      + NStr("vi = 'Tổng nợ phải trả khách hàng';
													|ru = 'Общая наша задолженность перед клиентом';
													|en = 'Our total debt owed to customer'; fa = 'Our total debt owed to customer';
													|it = 'Il nostro debito totale verso il cliente';
													|pl = 'Ogólne nasze zadłużenie wobec klienta';
													|tr = 'İstemci karşısında bizim toplam alacaklarımız/borçlarımız'") + " " 
		                                      + Left(ThisIsOurDuty,StrLen(ThisIsOurDuty)-2) + ".";
	EndIf;
	
	PrintSubsectionTitle(Template,ReportTable,TextCustomerDebt);
	
	If Not IsBlankString(OverdueDebtLine) Then
	
		OverdueDebtLine = NStr("vi = 'Công nợ quá hạn của khách hàng';
								|ru = 'Просроченная задолженность как клиента';
								|en = 'AR/AP overdue as a customer'; fa = 'AR/AP overdue as a customer';
								|it = 'Debito arretrato come cliente';
								|pl = 'Zaległości jako klienta';
								|tr = 'İstemcinin vadesi geçmiş borçları'") + " "
		                                  + Left(OverdueDebtLine,StrLen(OverdueDebtLine)-2) + ".";
		PrintSubsectionTitle(Template,ReportTable,OverdueDebtLine,StyleColors.OverdueDataColor);
	
	EndIf;
	
	// The output table
	ReportTable.StartRowGroup("CustomerDebt");
	OutputAreaWithoutParameters("CustomerDebtCap",Template,ReportTable);
	
	EvenString = False;
	CurrencySelection1.Reset();
	While CurrencySelection1.Next() Do
	
		DetailsSelection = CurrencySelection1.Select();
		While DetailsSelection.Next() Do
		
			Area = Template.GetArea("CustomerDebtLine");
			
			FillPropertyValues(Area.Parameters, DetailsSelection);
			
			If Not ValueIsFilled(DebtClassificationOption)
				And TypeOf(DetailsSelection.IntervalName) = Type("Number") Then
				Area.Parameters.IntervalName = String(DetailsSelection.IntervalName) + " " 
					+ TMCommonUseClientServer.DeclensionOfWord(
						DetailsSelection.IntervalName, 
						NStr("vi = 'ngày, ngày, ngày, m';
							|ru = 'день, дня, дней, м';
							|en = 'day, days, days'; fa = 'day, days, days';
							|it = 'день, дня, дней, м';
							|pl = 'dzień, dnia, dni, m';
							|tr = 'gün, gün, günler'"));
			EndIf; 
			If DetailsSelection.OverdueCustomerDebt > 0 Then
				
				SpreadsheetDocumentRange            = Area.Areas.CustomerDebtOverdueLine; //SpreadsheetDocumentRange
				SpreadsheetDocumentRange.TextColor = StyleColors.OverdueDataColor;
				SpreadsheetDocumentRange            = Area.Areas.LineCustomerDebtTermOverdueDebt; //SpreadsheetDocumentRange
				SpreadsheetDocumentRange.TextColor = StyleColors.OverdueDataColor;
			EndIf;
			
			If DetailsSelection.IntervalName = NStr("vi = 'Chưa cập nhật hạch toán';
													|ru = 'Расчеты не актуальны';
													|en = 'Calculations are not relevant'; fa = 'Calculations are not relevant';
													|it = 'Calcoli obsoleti';
													|pl = 'Obliczenia nie są aktualne';
													|tr = 'Hesaplamalar güncel değil'") Then
			
				AreaTableRow            = Area.Areas.CustomerDebtLine; // SpreadsheetDocumentRange
				AreaTableRow.TextColor = WebColors.LightGray;
				ThereAreCustomersARAPRequireUpdate = True;
			
			EndIf;
			If EvenString Then
				AreaTableRow          = Area.Areas.ARAPDocument; // SpreadsheetDocumentRange
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			EndIf;
			ReportTable.Put(Area,2);
			
			EvenString = Not EvenString;
		
		EndDo;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataOnSettlementsWithSupplier(ResultOfRequestForSettlements,ReportTable, Template)
	
	If ResultOfRequestForSettlements.IsEmpty() Then 
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	TitleText = NStr("vi = 'Nợ phải trả nhà cung cấp';
					|ru = 'Задолженность перед поставщиком';
					|en = 'Accounts payable'; fa = 'حساب‌های پرداختنی';
					|it = 'Debito verso fornitori';
					|pl = 'Zadłużenie wobec dostawcy';
					|tr = 'Tedarikçi borçları'") + " ";
	
	LineDebtToSupplier = "";
	OverdueDebtLine = "";
	
	CurrencySelection1 = ResultOfRequestForSettlements.Select(QueryResultIteration.ByGroups);
	While CurrencySelection1.Next() Do
		
		DutyToSupplier = CurrencySelection1.AccountsPayableOfCompany + CurrencySelection1.DebtOfSupplier;
		LineDebtToSupplier = LineDebtToSupplier + Format(DutyToSupplier, "NFD=2") + " " + CurrencySelection1.Currency + ", ";
		If CurrencySelection1.OurDebtOverdue <> 0 Then
			OverdueDebtLine = OverdueDebtLine + Format(CurrencySelection1.OurDebtOverdue, "NFD=2") + " " + CurrencySelection1.Currency + ", ";
		EndIf;
		
	EndDo;
	
	LineDebtToSupplier = NStr("vi = 'Tổng nợ phải trả nhà cung cấp';
								|ru = 'Общая задолженность перед поставщиком';
								|en = 'Total accounts payable'; fa = 'Total accounts payable';
								|it = 'Debito totale verso fornitori';
								|pl = 'Ogólne zadłużenie wobec dostawcy';
								|tr = 'Tedarikçi karşısında toplam borçlar'") + " "
	                             + Left(LineDebtToSupplier,StrLen(LineDebtToSupplier)-2) + ".";
	PrintSubsectionTitle(Template,ReportTable,LineDebtToSupplier);
	
	If Not IsBlankString(OverdueDebtLine) Then
	
		OverdueDebtLine = NStr("vi = 'Trong đó công nợ quá hạn';
								|ru = 'В том числе просроченная задолженность';
								|en = 'Including AR/AP overdue'; fa = 'Including AR/AP overdue';
								|it = 'Compreso il debito scaduto';
								|pl = 'W tym również przeterminowane zadłużenie';
								|tr = 'Vadesi geçmiş borçlar dahil'") + " "
		                                  + Left(OverdueDebtLine,StrLen(OverdueDebtLine)-2) + ".";
		PrintSubsectionTitle(Template,ReportTable,OverdueDebtLine,StyleColors.OverdueDataColor);
	
	EndIf; 
	
	// The output table
	ReportTable.StartRowGroup("SupplierSArrears");
	OutputAreaWithoutParameters("SupplierDebtCap",Template,ReportTable);
	
	EvenString = False;
	
	CurrencySelection1.Reset();
	While CurrencySelection1.Next() Do
	
		DetailsSelection = CurrencySelection1.Select();
		While DetailsSelection.Next() Do
		
			Area = Template.GetArea("SupplierDebtLine");
			FillPropertyValues(Area.Parameters, DetailsSelection);
			Area.Parameters.DebtOfSupplier = - Area.Parameters.DebtOfSupplier;
			If DetailsSelection.OurDebtOverdue > 0 Then
				AreaTableRow = Area.Areas.SupplierDebtLineOurDebtIsOverdue; // SpreadsheetDocumentRange
				AreaTableRow.TextColor = StyleColors.OverdueDataColor;
				AreaTableRow = Area.Areas.LineSupplierDebtDueDateOverdue; // SpreadsheetDocumentRange
				AreaTableRow.TextColor = StyleColors.OverdueDataColor;
			EndIf;
			If DetailsSelection.IntervalName = NStr("vi = 'Chưa cập nhật hạch toán';
													|ru = 'Расчеты не актуальны';
													|en = 'Calculations are not relevant'; fa = 'Calculations are not relevant';
													|it = 'Calcoli obsoleti';
													|pl = 'Obliczenia nie są aktualne';
													|tr = 'Hesaplamalar güncel değil'") Then
			
				AreaTableRow            = Area.Areas.SupplierDebtLine; // SpreadsheetDocumentRange
				AreaTableRow.TextColor = WebColors.LightGray;
				ThereAreVendorsARAPRequireUpdate = True;
			
			EndIf;
			
			If EvenString Then
				AreaTableRow            = Area.Areas.SettlementDocumentSupplier; // SpreadsheetDocumentRange
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			EndIf;
			
			ReportTable.Put(Area,2);
			
			EvenString = Not EvenString;
		
		EndDo;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

// Displays the report information about the classification of customers
// 
// Parameters:
// 	ClassificationQueryResult - QueryResult - data for classification.
// 	QueryResultPeriods         - QueryResult - data by period.
// 	ReportTable                   - SpreadsheetDocument - report table.
// 	Template                           - SpreadsheetDocument - report layout.
//
Procedure OutputClientClassificationData(ClassificationQueryResult,QueryResultPeriods,ReportTable, Template)

	If ClassificationQueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,ReportTable,NStr("vi = 'Phân loại';
													|ru = 'Классификация';
													|en = 'Classification'; fa = 'طبقه‌بندی';
													|it = 'Classificazione';
													|pl = 'Classification';
													|tr = 'Sınıflandırma'"));
	
	// The header of the table
	ReportTable.StartRowGroup("Classification");
	SamplePeriods = QueryResultPeriods.Select();
	SamplePeriods.Next();
	Area = Template.GetArea("ClassificationHeader");
	ClassificationPeriod = Constants.PeriodOfABCClassificationOfPartners.Get();
	Area.Parameters.PreviousPeriod_	= StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																										|ru = '%1 (%2)';
																										|en = '%1 (%2)'; fa = '%1 (%2)';
																										|it = '%1 (%2)';
																										|pl = '%1 (%2)';
																										|tr = '%1 (%2)'"),
	                                                                                              Format(SamplePeriods.PreviousPeriod_,
	                                                                                                    "DLF=D"),
	                                                                                              ClassificationPeriod);
	Area.Parameters.CurrentPeriod		= StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																										|ru = '%1 (%2)';
																										|en = '%1 (%2)'; fa = '%1 (%2)';
																										|it = '%1 (%2)';
																										|pl = '%1 (%2)';
																										|tr = '%1 (%2)'"), 
	                                                                                              Format(SamplePeriods.CurrentPeriod,
	                                                                                                    "DLF=D"),
	                                                                                              ClassificationPeriod);
	ReportTable.Put(Area);
	
	// Table Body
	
	SelectionParameterType = ClassificationQueryResult.Select(QueryResultIteration.ByGroups);
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	While SelectionParameterType.Next() Do
		
		Area = Template.GetArea("ClassificationString");
		
		If SelectionParameterType.ClassificationParameterType = Enums.TypesOfClassificationParameters.Revenue
		     Or SelectionParameterType.ClassificationParameterType = Enums.TypesOfClassificationParameters.GrossProfit Then
			
			TextClassificationParameter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2)';
																										|ru = '%1 (%2)';
																										|en = '%1 (%2)'; fa = '%1 (%2)';
																										|it = '%1 (%2)';
																										|pl = '%1 (%2)';
																										|tr = '%1 (%2)'"),
			                                                                                     String(SelectionParameterType.ClassificationParameterType),
			                                                                                     ManagementAccountingCurrency);
			
		Else
			
			TextClassificationParameter = NStr("vi = 'Số lượng mua';
												|ru = 'Количество покупок';
												|en = 'Number of purchases'; fa = 'تعداد خریدها';
												|it = 'Numero di acquisti';
												|pl = 'Ilość zakupów';
												|tr = 'Satın alımların miktarı'");
			
		EndIf;
		
		Area.Parameters.ClassificationParameter = TextClassificationParameter;
		CurrentClassification = "";
		PreviousClassification = "";
		DetailsSelection = SelectionParameterType.Select();
		While DetailsSelection.Next() Do
			If DetailsSelection.StringPeriod = "Current_" Then
				If (Not DetailsSelection.Class = Enums.ABCClassification.NotClassified) 
					  And (Not DetailsSelection.Class = Enums.XYZClassification.NotClassified) Then
					CurrentClassification = CurrentClassification + Left(DetailsSelection.Class,1) + ", ";
				EndIf;
				If DetailsSelection.ClassificationType = Enums.TypesOfClassification.ABC Then
					Area.Parameters.CurValue_ = DetailsSelection.ClassificationParameterValue;
				EndIf;
			Else
				If (Not DetailsSelection.Class = Enums.ABCClassification.NotClassified) 
					  And (Not DetailsSelection.Class = Enums.XYZClassification.NotClassified) Then
					PreviousClassification = PreviousClassification + Left(DetailsSelection.Class,1) + ", ";
				EndIf;
				If DetailsSelection.ClassificationType = Enums.TypesOfClassification.ABC Then
					Area.Parameters.ValuePrevious = DetailsSelection.ClassificationParameterValue;
				EndIf;
			EndIf;
		EndDo;
		Area.Parameters.ClassificationPrevious = Left(PreviousClassification,StrLen(PreviousClassification)-2);
		Area.Parameters.ClassificationCur    = Left(CurrentClassification,StrLen(CurrentClassification) - 2);
		
		ReportTable.Put(Area,2);
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataAboutPartnerSegments(QueryResultBySegment,ReportTable, Template);
	
	If QueryResultBySegment.IsEmpty() Then
		Return;
	EndIf;
	
	SampleResults = QueryResultBySegment.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	PrintSubsectionTitle(Template,
	                           ReportTable,
	                           StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thuộc các phân khúc - %1';
																							|ru = 'Входит в сегменты - %1.';
																							|en = 'Included in segments - %1.'; fa = 'Included in segments - %1.';
																							|it = 'Incluso nei segmenti - %1.';
																							|pl = 'Zawarte w segmentach - %1.';
																							|tr = 'Segmentlere dahil - %1.'"),
	                                                                                   SampleResults.Ref));
	
	ReportTable.StartRowGroup("Segments");
	OutputAreaWithoutParameters("HeaderSegments",Template,ReportTable);
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea("LineSegments");
		FillPropertyValues(Area.Parameters,DetailsSelection);
		If EvenString Then
			RowInPartnerSegmentsTable = Area.Areas.RowInPartnerSegmentsTable; //  SpreadsheetDocumentRange
			RowInPartnerSegmentsTable.BackColor = StyleColors.FieldAlternativeBackColor;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayDataOnCounterpartyAgreements(RequestResultForContracts,ReportTable, Template)
	
	If RequestResultForContracts.IsEmpty() Then
		Return;
	EndIf;
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	// The output caps
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	
	SampleResults = RequestResultForContracts.Select(QueryResultIteration.ByGroups);
	SampleResults.Next();
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hợp đồng có hiệu lực - %1.';
																				|ru = 'Действующих договоров - %1.';
																				|en = 'Valid contracts - %1.'; fa = 'Valid contracts - %1.';
																				|it = 'Contratti attivi - %1.';
																				|pl = 'Obowiązujących umów - %1.';
																				|tr = 'Geçerli sözleşmeler - %1.'"), 
	                                                                         SampleResults.Ref);
	PrintSubsectionTitle(Template,ReportTable,TitleText);
	
	// The output table
	ReportTable.StartRowGroup("CounterpartyContracts");
	OutputAreaWithoutParameters(?(UsePartnersAsCounterparties, "CounterpartyAgreementsHeaderPartnersAsCounterparties","CounterpartyAgreementsHeader"),Template,ReportTable);
	
	EvenString = False;
	DetailsSelection = SampleResults.Select();
	While DetailsSelection.Next() Do
	
		Area = Template.GetArea(?(UsePartnersAsCounterparties, "CounterpartyAgreementsPartnersAsCounterparties","ContractsOfCounterparties"));
		FillPropertyValues(Area.Parameters, DetailsSelection);
		If EvenString Then
			If UsePartnersAsCounterparties Then
				AreaTableRow = Area.Areas.RowOfTableContractsOfCounterpartiesPartnersAsCounterparties; // SpreadsheetDocumentRange
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			Else
				AreaTableRow = Area.Areas.RowOfContractsOfCounterpartiesTable; // SpreadsheetDocumentRange
				AreaTableRow.BackColor = StyleColors.FieldAlternativeBackColor;
			EndIf;
		EndIf;
		ReportTable.Put(Area,2);
		
		EvenString = Not EvenString;
	
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure OutputAreaWithoutParameters(AreaName,Template,ReportTable) Export

	Area = Template.GetArea(AreaName);
	ReportTable.Put(Area);

EndProcedure

// Displays the subsection title in the report
// 
// Parameters:
// 	Template - SpreadsheetDocument - LongDesc
// 	ReportTable - SpreadsheetDocument - 
// 	TitleText - String - LongDesc
// 	TextColor - Undefined, Color - LongDesc
//
Procedure PrintSubsectionTitle(Template,ReportTable,TitleText,TextColor = Undefined) Export

	Area = Template.GetArea("SubsectionTitle");
	Area.Parameters.Title = TitleText;
	If TextColor <> Undefined Then
		SubsectionTitle = Area.Areas.SubsectionTitle;  //SpreadsheetDocumentRange
		SubsectionTitle.TextColor = TextColor;
	EndIf;
	ReportTable.Put(Area);

EndProcedure

#EndRegion

#Region Other

// Generates a report
//
// Parameters:
//  ReportTable - SpreadsheetDocument - Table document to display the report in
//  Partner       - CatalogRef.Partners - the partner for which the report is generated.
//
Procedure GenerateReport(ReportTable, Partner)  Export
	
	Template = GetTemplate("Template");
	
	MatchingRequestsData = New Map;
	ArrayOfQueryResultsForPartner = ExecuteBatchOfRequestsForPartner(Partner,MatchingRequestsData);
	
	If MatchingRequestsData["PartnerData"] <> Undefined Then
		OutputPartnerData(ArrayOfQueryResultsForPartner[0],
		                      ArrayOfQueryResultsForPartner[1],
		                      ?(MatchingRequestsData["PrimaryInterest"]=Undefined,
		                              Undefined,
		                              ArrayOfQueryResultsForPartner[MatchingRequestsData["PrimaryInterest"]]),
		                      ReportTable,Template);
	EndIf;
	
	If Contacts Then
		If MatchingRequestsData["PartnerContactInformation"] <> Undefined Then
			DisplayDataAboutPartnerSContactInformation(ArrayOfQueryResultsForPartner[MatchingRequestsData["PartnerContactInformation"]], 
			                                           ReportTable,Template);
		EndIf;
		If MatchingRequestsData["SuperiorPartners"] <> Undefined Then
			DisplayDataAboutUpstreamPartners(ArrayOfQueryResultsForPartner[MatchingRequestsData["SuperiorPartners"]],
			                                   ReportTable,Template);
		EndIf;
		If MatchingRequestsData["ContactPersons"] <> Undefined Then
			DisplayInformationAboutContactPersons(ArrayOfQueryResultsForPartner[MatchingRequestsData["ContactPersons"]],
			                                                                  ReportTable,Template);
		EndIf;
		If MatchingRequestsData["Counterparties"] <> Undefined Then
			DisplayDataAboutCounterparties(ArrayOfQueryResultsForPartner[MatchingRequestsData["Counterparties"]],ReportTable,Template);
		EndIf;
	EndIf;
	If ClientData Then
		If MatchingRequestsData["SettlementsWithClient"] <> Undefined Then
			DisplayDataOnSettlementsWithClient(ArrayOfQueryResultsForPartner[MatchingRequestsData["SettlementsWithClient"]],
			                                      ReportTable, Template);
		EndIf;
	EndIf;
	If VendorData Then
		If MatchingRequestsData["SettlementsWithSupplier"] <> Undefined Then
			DisplayDataOnSettlementsWithSupplier(ArrayOfQueryResultsForPartner[MatchingRequestsData["SettlementsWithSupplier"]],
			                                         ReportTable, Template);
		EndIf;
		
		CRMLocalization.WhenDisplayingSupplierSDataPartnerSDossierReport(ThisObject, ArrayOfQueryResultsForPartner, MatchingRequestsData, ReportTable, Template);
		
	EndIf;
	If ClientData Or VendorData Then
		If MatchingRequestsData["CounterpartyContracts"] <> Undefined Then
			DisplayDataOnCounterpartyAgreements(ArrayOfQueryResultsForPartner[MatchingRequestsData["CounterpartyContracts"]],
			                                    ReportTable, Template);
		EndIf;
	EndIf;
	If ClientData Then
		If MatchingRequestsData["PendingClaims"] <> Undefined Then
			OutputDataIncompleteClaims(ArrayOfQueryResultsForPartner[MatchingRequestsData["PendingClaims"]],
			                                    ReportTable, Template);
		EndIf;
		If MatchingRequestsData["ReportsOfDiscrepanciesAfterShipment"] <> Undefined Then
			DisplayDataUnprocessedReportsOfDiscrepanciesAfterShipment(ArrayOfQueryResultsForPartner[MatchingRequestsData["ReportsOfDiscrepanciesAfterShipment"]],
			                                               ReportTable, Template);
		EndIf;
		If MatchingRequestsData["Turnovers"] <> Undefined Then
			DisplayTheseRevolutions(ArrayOfQueryResultsForPartner[MatchingRequestsData["Turnovers"]],
			                     ReportTable, Template);
		EndIf;
		If MatchingRequestsData["AvailableAgreements"] <> Undefined Then
			DisplayDataAboutAvailableAgreements(ArrayOfQueryResultsForPartner[MatchingRequestsData["AvailableAgreements"]],
			                                   ReportTable, Template);
		EndIf;
		If MatchingRequestsData["CurTransactions_"] <> Undefined Then
			DisplayDataOnCurTransactionsWithClient(ArrayOfQueryResultsForPartner[MatchingRequestsData["CurTransactions_"]],
			                                      ReportTable,Template);
		EndIf;
		If MatchingRequestsData["Orders"] <> Undefined Then
			DisplayDataAboutPartnerOrders(ArrayOfQueryResultsForPartner[MatchingRequestsData["Orders"]],
			                              ReportTable, Template, NStr("vi = 'khách hàng';
																		|ru = 'клиента';
																		|en = 'of customer'; fa = 'of customer';
																		|it = 'del cliente';
																		|pl = 'of customer';
																		|tr = 'müşteri'"));
		EndIf;
		If MatchingRequestsData["RequestsForReturn"] <> Undefined Then
			DisplayDataAboutPartnerOrders(ArrayOfQueryResultsForPartner[MatchingRequestsData["RequestsForReturn"]],
			                              ReportTable, Template, "ReturnRequest");
		EndIf;
		
		CRMLocalization.WhenClientSDataIsOutputPartnerSDossierReport(ThisObject, ArrayOfQueryResultsForPartner, MatchingRequestsData, ReportTable, Template);

	EndIf;
	If VendorData Then
		If MatchingRequestsData["TermsOfPurchase"] <> Undefined Then
			DisplayInformationAboutAgreementsWithSupplier(ArrayOfQueryResultsForPartner[MatchingRequestsData["TermsOfPurchase"]],
			                                      ReportTable, Template);
		EndIf;
		If MatchingRequestsData["OrdersToSupplier"] <> Undefined Then
			DisplayDataAboutPartnerOrders(ArrayOfQueryResultsForPartner[MatchingRequestsData["OrdersToSupplier"]],
			                              ReportTable, Template,NStr("vi = 'dành cho nhà cung cấp';
																	|ru = 'поставщику';
																	|en = 'vendor'; fa = 'تأمین‌کننده';
																	|it = 'al fornitore';
																	|pl = 'vendor';
																	|tr = 'tedarikçiye'"));
		EndIf;
	EndIf;
	If CurrentActivity Then
		If MatchingRequestsData["UnprocessedInteractions"] <> Undefined Then
			OutputDataOnUnprocessedInteractions(ArrayOfQueryResultsForPartner[MatchingRequestsData["UnprocessedInteractions"]],
			                                            ReportTable, Template);
		EndIf;
		If MatchingRequestsData["ParticipationInSalesOpportunities"] <> Undefined Then
			DisplayDataOnTransactionsInvolvingPartner(ArrayOfQueryResultsForPartner[MatchingRequestsData["ParticipationInSalesOpportunities"]],
			                                       ArrayOfQueryResultsForPartner[MatchingRequestsData["ParticipationInSalesOpportunities"]+1],
			                                       ReportTable, Template);
		EndIf;
		If MatchingRequestsData["OtherProjects"] <> Undefined Then
			DisplayDataOnPartnerSParticipationInOtherProjects(ArrayOfQueryResultsForPartner[MatchingRequestsData["OtherProjects"]],
			                                             ArrayOfQueryResultsForPartner[MatchingRequestsData["OtherProjects"]+1],
			                                             ReportTable, Template);
		EndIf;
	EndIf;
	If Classification Then
		If MatchingRequestsData["ClientClassification"] <> Undefined Then
			OutputClientClassificationData(ArrayOfQueryResultsForPartner[MatchingRequestsData["ClientClassification"]],
			                                   ArrayOfQueryResultsForPartner[MatchingRequestsData["ClientClassification"]+1],
			                                   ReportTable, Template);
		EndIf;
		If MatchingRequestsData["PartnerSegments"] <> Undefined Then
			DisplayDataAboutPartnerSegments(ArrayOfQueryResultsForPartner[MatchingRequestsData["PartnerSegments"]],
			                                ReportTable, Template);
		EndIf;
	EndIf;
	
	OutputAreaWithoutParameters("IsBlankString",Template,ReportTable);
	ReportTable.PutHorizontalPageBreak();
	
EndProcedure

Function MultiLinePresentationOfContactInformation(ContactInformation)

	KiPresentation = "";
	
	For Each ContactInformationRow In ContactInformation Do
		
		If Not ValueIsFilled(ContactInformationRow.Presentation) Then
			Continue;
		EndIf;
		
		KiPresentation = KiPresentation + "
		|" + ContactInformationRow.Kind + ": " + ContactInformationRow.Presentation;
	
	EndDo;
	
	Return Right(KiPresentation,StrLen(KiPresentation)-1);

EndFunction

Function MultiLinePresentationOfContactPersonRoles(ContactPersonRoles)
	
	RolePresentation = "";
	RoleTable = ContactPersonRoles.Unload();
	RoleTable.Sort("LineNumber Desc");
	
	For Each StringRole In RoleTable Do
		
		RolePresentation = RolePresentation + "
		|" + StringRole.ContactRole;
		
	EndDo;
	
	Return Right(RolePresentation,StrLen(RolePresentation)-1);
	
EndFunction

Function PartnerRoleStringInTransaction(SelectingRoleDetails)
	
	GeneratedString = "";
	While SelectingRoleDetails.Next() Do
		
		If StrOccurrenceCount(GeneratedString,SelectingRoleDetails.PartnerSRole) = 0 Then
			
			GeneratedString = GeneratedString + SelectingRoleDetails.PartnerSRole + ", ";
			
		EndIf;
		
	EndDo;
	
	SelectingRoleDetails.Reset();
	
	Return Left(GeneratedString,StrLen(GeneratedString)-2) ;
	
EndFunction

Function RoleStringOfContactPersonsInTransaction(SelectingRoleDetails)
	
	GeneratedString = "";
	While SelectingRoleDetails.Next() Do
		
		LengthOfStringBeforeProcessing = StrLen(GeneratedString);
		
		GeneratedString = GeneratedString + ?(ValueIsFilled(SelectingRoleDetails.ContactPerson),String(SelectingRoleDetails.ContactPerson)
		                    + ?(ValueIsFilled(SelectingRoleDetails.ContactRole)," - " + SelectingRoleDetails.ContactRole,""),"");
		
		If  StrLen(GeneratedString) > LengthOfStringBeforeProcessing Then
			GeneratedString = GeneratedString + "
			|";
		EndIf;
		
	EndDo;
	
	SelectingRoleDetails.Reset();
	
	Return Left(GeneratedString,StrLen(GeneratedString)-1);
	
EndFunction

#EndRegion

#EndRegion

#EndIf