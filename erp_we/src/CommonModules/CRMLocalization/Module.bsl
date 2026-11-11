
#Region Public

#Region SalesOpportunities

Procedure AddRequestToCalculateTransactionPotential(QueryText) Export
	
	If Not GetFunctionalOption("UseCommercialProposalsForCustomers") Then
		Return;
	EndIf;
	
	StringArrange = "
	|
	|ORDER BY
	|	DORDER";
	
	QueryText = StrReplace(QueryText, StringArrange, "");
	
	QueryText = QueryText + "
	|
	|UNION ALL
	|
	|SELECT
	|	CommercialProposalForCustomer.Ref,
	|	2.5,
	|	CASE
	|		WHEN CommercialProposalForCustomer.Currency = ManSExchangeRates.Currency
	|			THEN CommercialProposalForCustomer.DocumentAmount
	|		ELSE CommercialProposalForCustomer.DocumentAmount * ISNULL(DocumentCurrencyRates.CourseNumerator, 1) * ISNULL(ManSExchangeRates.CourseDenominator, 1) / (ISNULL(ManSExchangeRates.CourseNumerator, 1) * ISNULL(DocumentCurrencyRates.CourseDenominator, 1))
	|	END,
	|	PRESENTATION(CommercialProposalForCustomer.Status)
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS DocumentCurrencyRates
	|		ON CommercialProposalForCustomer.Currency = DocumentCurrencyRates.Currency,
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			,
	|			Currency IN
	|				(SELECT
	|					Constants.ManagementAccountingCurrency
	|				FROM
	|					Constants AS Constants)
	|			AND BaseCurrency = &BaseCurrency) AS ManSExchangeRates
	|WHERE
	|	CommercialProposalForCustomer.DeletionMark = FALSE
	|	AND CommercialProposalForCustomer.SalesOpportunity = &FilterDocument_
	|	AND CommercialProposalForCustomer.DocumentAmount > 0
	|";
	
	QueryText = QueryText + StringArrange;
	
EndProcedure

#EndRegion

#Region PartnerAndSalesOpportunityDocuments

Procedure AddRequestConditionBasedOnDocumentRelevance(DocumentName, ConditionText) Export
	
	If DocumentName = "CommercialProposalForCustomer" Then
		
		ConditionText = ConditionText 
		               + ?(IsBlankString(ConditionText),"", " And ")
		               + " %PathToPropsTable%.Status <> VALUE(Enum.StatusesOfCommercialProposalsForCustomers.Canceled)";
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SalesCompositionReport

Procedure CompleteListOfDocumentsFormingSalesReport(ListOfNamesOfTabularPartsOfDocuments) Export
	
	ListOfNamesOfTabularPartsOfDocuments.Insert(0, "CommercialProposalForCustomer.Goods", NStr("vi = 'Trong báo giá';
																								|ru = 'В коммерческих предложениях';
																								|en = 'In sales quotations'; fa = 'In sales quotations';
																								|it = 'Nelle offerte commerciali';
																								|pl = 'W ofertach komercyjnych';
																								|tr = 'Satış tekliflerinde'"));
	
EndProcedure

#EndRegion

#Region PartnerProfile

Procedure AddRequestTextToPartnerSDossierReport(ReportObject, Query, MatchingRequestsData, LastPacketNumber) Export
	
	
EndProcedure

Procedure WhenClientSDataIsOutputPartnerSDossierReport(ReportObject, ArrayOfQueryResultsForPartner, MatchingRequestsData, ReportTable, Template) Export
	
	
EndProcedure

Procedure WhenDisplayingSupplierSDataPartnerSDossierReport(ReportObject, ArrayOfQueryResultsForPartner, MatchingRequestsData, ReportTable, Template) Export
	
	
EndProcedure

#EndRegion

#Region EventCalendar

Procedure WhenGettingRequestTextByEventType(ReportObject, EventKind, Query, QueryText, StructureOfReportGeneration) Export
	
	If EventKind = "CommercialProposals" Then
		QueryText = RequestTextCommercialOffersCalendarOfEvents(ReportObject, Query, QueryText, StructureOfReportGeneration);
	EndIf;
	
EndProcedure

Procedure AddEventTreeToEventCalendarReport(ParentNode) Export
	
	ThereIsRightOfCommercialOffersOfClients    = AccessRight("Read",Metadata.Documents.CommercialProposalForCustomer);
	CommercialOffersToClientsAreUsed = GetFunctionalOption("UseCommercialProposalsForCustomers");
	
	If ParentNode.EventKind = "Sales" 
		And ThereIsRightOfCommercialOffersOfClients
		And CommercialOffersToClientsAreUsed Then
		
		AddEventViewToTree(ParentNode, "CommercialProposals", NStr("vi = 'Báo giá cho khách hàng';
																	|ru = 'Коммерческие предложения клиентам';
																	|en = 'Sales quotations'; fa = 'پیشنهادهای فروش';
																	|it = 'Offerte commerciali ai clienti';
																	|pl = 'Oferty komercyjne do klientów';
																	|tr = 'Müşterilere sunulan satış teklifleri'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private


#Region EventCalendar

Function RequestTextCommercialOffersCalendarOfEvents(ReportObject, Query, QueryText, StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	CommercialProposalForCustomer.Ref AS ReferenceToEventObject,
	|	CommercialProposalForCustomer.Ref AS SubjectOf,
	|	&ApprovalOfKP AS EventType,
	|	CommercialProposalForCustomer.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	CommercialProposalForCustomer.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	CommercialProposalForCustomer.Client  AS Partner,
	|	CommercialProposalForCustomer.Manager AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Posted
	|	AND CommercialProposalForCustomer.Status = VALUE(Enum.StatusesOfCommercialProposalsForCustomers.NotApproved)
	|	AND CASE
	|			WHEN CommercialProposalForCustomer.ValidityPeriod = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE CommercialProposalForCustomer.ValidityPeriod >= BEGINOFPERIOD(&CurrentDate, DAY)
	|		END 
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	CommercialProposalForCustomer.Ref,
	|	CommercialProposalForCustomer.Ref AS SubjectOf,
	|	&ExpirationOfCP,
	|	CommercialProposalForCustomer.Date,
	|	CASE
	|		WHEN CommercialProposalForCustomer.ValidityPeriod = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(&CurrentDate, DAY)
	|		ELSE ENDOFPERIOD(CommercialProposalForCustomer.ValidityPeriod,DAY)
	|	END,
	|	CommercialProposalForCustomer.Presentation,
	|	NULL,
	|	NULL,
	|	CASE
	|		WHEN CommercialProposalForCustomer.ValidityPeriod = DATETIME(1, 1, 1)
	|			THEN &CurrentBusinessUnit
	|		ELSE CASE
	|				WHEN CommercialProposalForCustomer.ValidityPeriod = BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &CurrentBusinessUnit
	|				ELSE &Upcoming
	|			END
	|	END,
	|	CommercialProposalForCustomer.Client,
	|	CommercialProposalForCustomer.Manager
	|   ,&TextEmptyString
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Posted
	|	AND CommercialProposalForCustomer.Status = VALUE(Enum.StatusesOfCommercialProposalsForCustomers.Valid)
	|	AND CommercialProposalForCustomer.ValidityPeriod <> DATETIME(1, 1, 1)
	|	AND CommercialProposalForCustomer.ValidityPeriod < &EndDate
	|	AND CommercialProposalForCustomer.ValidityPeriod >= BEGINOFPERIOD(&CurrentDate, DAY) 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ExpirationOfCP",NStr("vi = 'Kết thúc thời hạn thực hiện báo giá';
											|ru = 'Окончание срока действия коммерческого предложения';
											|en = 'Sales quotation expiration'; fa = 'Sales quotation expiration';
											|it = 'Data di fine validità dell''offerta commerciale';
											|pl = 'Data wygaśnięcia oferty handlowej';
											|tr = 'Satış teklifinin sona ermesi'"));
	Query.SetParameter("ApprovalOfKP",NStr("vi = 'Thống nhất báo giá';
											|ru = 'Согласовать коммерческое предложения';
											|en = 'Approve sales quotation'; fa = 'Approve sales quotation';
											|it = 'Concordare l''offerta commerciale';
											|pl = 'Uzgodnij oferty handlowej';
											|tr = 'Satış teklifini onayla'"));
	
	ReportObject.AddRequestForIssues(QueryText,"Document.CommercialProposalForCustomer",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND CommercialProposalForCustomer.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ReportObject.ProcessSubqueryTextByEventType(QueryText, StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	ReportObject.AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.CommercialProposalForCustomer");
	
	Return QueryText;

EndFunction

// Adds a new event type to the event tree
// 
// Parameters:
//  ParentRow  - FormDataTree - a group of events.
//  EventKind      - String - event name.
//  Presentation   - String - the representation of the event.
//
// Returns:
//   ValueTreeRow
// 	
Function AddEventViewToTree(ParentRow, EventKind, Presentation)
	
	NewRow = ParentRow.GetItems().Add();
	NewRow.EventKind = EventKind;
	NewRow.Presentation = Presentation;
	Return NewRow

EndFunction

#EndRegion

#EndRegion


