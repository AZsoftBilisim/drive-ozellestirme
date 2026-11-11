#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Department", Parameters);
	
EndProcedure

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	
	#Region Attributes
	
	// Who decided
	Item = Settings.Add();
	Item.Fields.Add("WhoDecided");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.EmployeeApplicationStatuses.AgreedUpon);
	Item.Properties.Insert("Visible");
	
	// Group of employees
	Item = Settings.Add();
	Item.Fields.Add("EmployeesHREmployee");
	Item.Fields.Add("GroupSecondedEmployees");
	Item.Fields.Add("FillInEmployees");
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Employee");
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Item.Properties.Insert("Enabled", False);
	
	// LabelActualPayment
	Item = Settings.Add();
	Item.Fields.Add("LabelActualPayment");
	Finances.NewFilter(Item.Condition, "Status", Enums.EmployeeApplicationStatuses.AgreedUpon);
	Item.Properties.Insert("Visible");
	
	// LabelBookingStatus
	Item = Settings.Add();
	Item.Fields.Add("LabelBookingStatus");
	Finances.NewFilter(Item.Condition, "Ref",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(Item.Condition, "Status", Enums.EmployeeApplicationStatuses.AgreedUpon);
	Finances.NewFilter(Item.Condition, "More.UseSmartwayIntegration", True);
	Item.Properties.Insert("Visible");
	
	// Over the limit
	Item = Settings.Add();
	Item.Fields.Add("OverLimits");
	Finances.NewFilter(Item.Condition, "OverLimits", True);
	Item.Properties.Insert("TitleTextColor", StyleColors.SpecialTextColor);
	
	Item = Settings.Add();
	Item.Fields.Add("OverLimits");
	Finances.NewFilter(Item.Condition, "OverLimits", False);
	Item.Properties.Insert("TitleTextColor", StyleColors.FormTextColor);
	
	// To close the application
	Item = Settings.Add();
	Item.Fields.Add("CloseRequest");
	Finances.NewFilter(Item.Condition, "More.BalanceOfPayment", 0,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(Item.Condition, "Posted", True);
	Finances.NewFilter(Item.Condition, "Closed_", False);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.EmployeeApplicationStatuses.IsPrepared);
	Finances.NewFilter(OrGroup, "Status", Enums.EmployeeApplicationStatuses.Considered);
	Finances.NewFilter(OrGroup, "Status", Enums.EmployeeApplicationStatuses.AgreedUpon);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Closed_");
	Finances.NewFilter(Item.Condition, "Closed_", True);
	Item.Properties.Insert("Visible");
	
	// Personal account
	Item = Settings.Add();
	Item.Fields.Add("PersonalAccount");
	Finances.NewFilter(Item.Condition, "PersonsList", False);
	Item.Properties.Insert("Visible");
	
	// Form of payment
	Item = Settings.Add();
	Item.Fields.Add("PersonalAccount");
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	Finances.NewFilter(Item.Condition, "PersonsList", False);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("EmployeesHRPersonalAccount");
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccount");
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CashAccount");
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.CashAccountPayment_);
	Item.Properties.Insert("Visible");
	
	// Tickets
	Item = Settings.Add();
	Item.Fields.Add("BookDepartureToDestination");
	Item.Fields.Add("BookDepartureToDestinationNotEarlier");
	Item.Fields.Add("BookArrivalToDestination");
	Item.Fields.Add("BookArrivalToDestinationNotLater");
	Item.Fields.Add("BookAirlineToDestination");
	Item.Fields.Add("BookTrainToDestination");
	Item.Fields.Add("BookTransferToDestination");
	Finances.NewFilter(Item.Condition, "BookTicketsToDestination", True);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("BookDepartureToDestinationNotEarlier");
	Item.Fields.Add("BookArrivalToDestinationNotLater");
	Finances.NewFilter(Item.Condition, "BookTicketsToDestination", True);
	Item.Properties.Insert("AutoMarkIncomplete");
	Item.Properties.Insert("MarkIncomplete");
	
	Item = Settings.Add();
	Item.Fields.Add("BookDestinationTransferLocation");
	Finances.NewFilter(Item.Condition, "BookTicketsToDestination", True);
	Finances.NewFilter(Item.Condition, "BookTransferToDestination", True);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("BookDestinationTransferLocation");
	Finances.NewFilter(Item.Condition, "BookTicketsToDestination", True);
	Finances.NewFilter(Item.Condition, "BookTransferToDestination", True);
	Item.Properties.Insert("AutoMarkIncomplete");
	Item.Properties.Insert("MarkIncomplete");
	
	Item = Settings.Add();
	Item.Fields.Add("BookReturnDeparture");
	Item.Fields.Add("BookReturnDepartureNotEarlier");
	Item.Fields.Add("BookArrivalBack");
	Item.Fields.Add("BookArrivalBackNotLater");
	Item.Fields.Add("BookAirlineBack");
	Item.Fields.Add("BookTrainBack");
	Item.Fields.Add("BookTransferBack");
	Finances.NewFilter(Item.Condition, "BookReturnTickets", True);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("BookReturnDepartureNotEarlier");
	Item.Fields.Add("BookArrivalBackNotLater");
	Finances.NewFilter(Item.Condition, "BookReturnTickets", True);
	Item.Properties.Insert("AutoMarkIncomplete");
	Item.Properties.Insert("MarkIncomplete");
	
	Item = Settings.Add();
	Item.Fields.Add("BookReturnTransferLocation");
	Finances.NewFilter(Item.Condition, "BookReturnTickets", True);
	Finances.NewFilter(Item.Condition, "BookTransferBack", True);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("BookReturnTransferLocation");
	Finances.NewFilter(Item.Condition, "BookReturnTickets", True);
	Finances.NewFilter(Item.Condition, "BookTransferBack", True);
	Item.Properties.Insert("AutoMarkIncomplete");
	Item.Properties.Insert("MarkIncomplete");
	
	Item = Settings.Add();
	Item.Fields.Add("BookAccommodation_");
	Item.Fields.Add("BookAccommodationStartDate");
	Item.Fields.Add("BookAccommodationEndDate");
	Item.Fields.Add("BookAccommodations");
	Finances.NewFilter(Item.Condition, "BookAccommodation", True);
	Item.Properties.Insert("Enabled");
	Item.Properties.Insert("AutoMarkIncomplete");
	Item.Properties.Insert("MarkIncomplete");
	
	// Currency
	Item = Settings.Add();
	Item.Fields.Add("Currency");
	Finances.NewFilter(Item.Condition, "RequiredPaymentDate", , , DataCompositionComparisonType.Filled);
	Item.Properties.Insert("AutoMarkIncomplete");
	
	#EndRegion
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	NewCommand = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Handler = "GenerationByReferenceTMClient.CreateSpendingCashOrder";
		NewCommand.VisibilityInForms = "DocumentForm, ListForm";
		NewCommand.MultipleChoice = True;
	EndIf;
	
	NewCommand = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Handler = "GenerationByReferenceTMClient.CreateNonCashCashDebiting";
		NewCommand.VisibilityInForms = "DocumentForm, ListForm";
		NewCommand.MultipleChoice = True;
	EndIf;
	
	NewCommand = Documents.ExpenseReport.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.VisibilityInForms = "DocumentForm, ListForm";
		NewCommand.MultipleChoice = False;
	EndIf;
	
	NewCommand = Documents.ElectronicTicketTransaction.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Presentation = NStr("vi = 'Vé điện tử';
										|ru = 'Электронный билет';
										|en = 'Electronic ticket'; fa = 'بلیت الکترونیکی';
										|it = 'Biglietto elettronico';
										|pl = 'Bilet elektroniczny';
										|tr = 'Elektronik bilet'");
		NewCommand.VisibilityInForms = "DocumentForm, ListForm";
		NewCommand.MultipleChoice = False;
	EndIf;
	
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CashFlowLimits.AddReportCommand(ReportsCommands);
	Reports.FulfillmentOfPaymentRequests.AddReportCommand(ReportsCommands);
	Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest.AddReportCommand(ReportsCommands);
	Reports.LimitsByBudgetingData.AddReportCommand(ReportsCommands);
EndProcedure

// Defines the details of the selected document
//
// Parameters:
//	Ref - DocumentRef.ApplicationForBusinessTrip - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function ObjectAttributes(Ref) Export
	
	ObjectAttributes = New Structure;
	
	Query = New Query("
	|SELECT
	|	Data.StartDate       AS StartDate,
	|	Data.EndDate    AS EndDate,
	|	Data.Organization      AS Organization,
	|	Data.Employee        AS Employee,
	|	Data.Posted         AS Posted
	|FROM
	|	Document.ApplicationForBusinessTrip AS Data
	|WHERE
	|	Data.Ref = &Ref
	|");
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		ObjectAttributes.Insert(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Return ObjectAttributes;
	
EndFunction

#Region BDRLimits

// Returns the flag for using BDR limits in business trip requests.
// 
// Returns:
//  Boolean
Function UseBDRLimits() Export
	
	ReturnValue = False;
	ReturnValue = LimitsByBudgetingDataServer.UseBDRLimits();
	Return ReturnValue;
	
EndFunction

#EndRegion

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text = "AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(EmployeeResponsible)
	|";

EndProcedure
// End StandardSubsystems.AccessManagement

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("PlanningCashControl");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ApplicationForBusinessTrip") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers);
		QueryTextTableCashFlowLimits(Query, QueryTexts, Registers);
		QueryTextTableCashFlow(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;

	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Expenses";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionOfExpenses");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

// Fills in the submitted document
//
// Parameters:
//    Object - DocumentObject - The document to be filled in.
//    Ref - DocumentRef - document basis "application for a business trip".
//
Procedure FillInUsingBaseDocument(Object, Ref) Export
	
	ObjectType = TypeOf(Object);
	
	QueryTextCaps = "";
	
	If ObjectType = Type("DocumentObject.ElectronicTicketTransaction") Then
		QueryTextCaps = QueryTextBooking();
	EndIf;
	
	If Not ValueIsFilled(QueryTextCaps) Then
		ErrorText = StrTemplate(NStr("vi = 'Không cho phép nhập chứng từ %1 trên cơ sở chứng từ %2.';
									|ru = 'Не предусмотрен ввод документа %1 на основании документа %2.';
									|en = 'Entry of document %1 based on document %2 is not available.'; fa = 'Entry of document %1 based on document %2 is not available.';
									|it = 'Non è previsto l''inserimento del documento %1 in base al documento %2.';
									|pl = 'Nie przywidziano wprowadzenia dokumentu %1 na podstawie dokumentu %2.';
									|tr = '%1 belge girişi, %2 belgesi esasında öngörülmedi.'"),
			Object.Metadata().Synonym, Ref);
		Raise ErrorText;
	EndIf;
	
	Query = New Query(QueryTextCaps);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập chứng từ %1 trên cơ sở chứng từ %2.';
				|ru = 'Не требуется вводить документ %1 на основании документа %2.';
				|en = 'It is not required to enter document %1 based on document %2.'; fa = 'It is not required to enter document %1 based on document %2.';
				|it = 'Non è richiesto inserire il documento %1 in base al documento %2.';
				|pl = 'Nie trzeba wprowadzać dokumentu %1 na podstawie dokumentu %2.';
				|tr = '%2 belgesine göre %1 belgesini girmeye gerek yok.'"),
			Object.Metadata().Synonym,
			Ref);
		Raise ErrorText;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FillPropertyValues(Object, Selection);
	
EndProcedure


// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	Return;
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("StartDate");
	Fields.Add("EndDate");
	Fields.Add("PlaceOfDestination");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If ValueIsFilled(Data.StartDate) And ValueIsFilled(Data.EndDate) Then
		StandardProcessing = False;
		Presentation = StrTemplate(NStr("vi = 'Giấy đăng ký đi công tác %1 ngày %2 (%3 - %4 %5)';
										|ru = 'Заявка на командировку %1 от %2 (%3 - %4 %5)';
										|en = 'Travel request %1 dated %2 (%3 - %4 %5)'; fa = 'Travel request %1 dated %2 (%3 - %4 %5)';
										|it = 'Richiesta di viaggio di lavoro %1 del %2 (%3 - %4 %5)';
										|pl = 'Zgłoszenie podróży służbowej %1 z dn. %2 (%3 - %4 %5)';
										|tr = 'Seyahat başvurusu %2 tarihinden %1 kadar (%3 - %4 %5)'"),
			Data.Number, Data.Date, Format(Data.StartDate, "DLF=D"), Format(Data.EndDate, "DLF=D"), Data.PlaceOfDestination);
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ApplicationForBusinessTrip";
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	If RegisterName = "CashToBePaid" Then
		
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                                     AS Period,
	|	DocumentData.RequiredPaymentDate                   AS RequiredPaymentDate,
	|	DocumentData.Organization                              AS Organization,
	|	DocumentData.Department                            AS Department,
	|	DocumentData.Employee                                AS Employee,
	|	DocumentData.Partner                                  AS Partner,
	|	DocumentData.Currency                                   AS Currency,
	|	DocumentData.Status                                   AS Status,
	|	DocumentData.CashFlowItem            AS CashFlowItem,
	|	DocumentData.PaymentMethodOfPaymentRequest                        AS PaymentMethod,
	|	DocumentData.OverLimits                              AS OverLimits,
	|
	|	DocumentData.BankAccount                           AS BankAccount,
	|	DocumentData.Number                                    AS Number,
	|	DocumentData.Target                                     AS PaymentPurposes,
	|	DocumentData.Comment                              AS Comment,
	|	DocumentData.Posted                                 AS Posted,
	|	DocumentData.DeletionMark                          AS DeletionMark,
	|	DocumentData.DocumentAmount                           AS DocumentAmount,
	|	DocumentData.EmployeeResponsible                            AS EmployeeResponsible
	|FROM
	|	Document.ApplicationForBusinessTrip AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                   Common.MetadataObjectID("Document.ApplicationForBusinessTrip"));
	Values.Insert("BusinessOperation",                     Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	Values.Insert("UseCashFlowLimits",  GetFunctionalOption("UseCashFlowLimits"));
	Values.Insert("UseExpenseLimitsForOrganizations",   GetFunctionalOption("UseCashFlowLimitsByCompanies"));
	Values.Insert("UseExpenseLimitsByDivision", GetFunctionalOption("UseCashFlowLimitsByBusinessUnit"));
	
	If Attributes <> Undefined Then
		Values.Insert("CashFlowItem",         CashFlowArticleOfDocument(Attributes));
		Values.Insert("OverLimits",                           Attributes.OverLimits);
		Values.Insert("NumberForPrinting",                         ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableCashToBePaid(Query, QueryTexts, Registers)
	
	RegisterName = "CashToBePaid";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&RequiredPaymentDate                AS Period,
	|	&Ref                                AS PaymentRequest,
	|	CASE DocumentData.Ref.PaymentMethodOfPaymentRequest
	|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|			DocumentData.Ref.CashAccount
	|		WHEN VALUE(Enum.PaymentForms.BankAccountPayment) THEN
	|			DocumentData.Ref.BankAccount
	|		ELSE
	|			UNDEFINED
	|	END AS BankAccountCashAccount,
	|	DocumentData.Employee              AS Recipient,
	|	&Organization                           AS Organization,
	|	
	|	DocumentData.Sum                  AS Sum,
	|	
	|	&BusinessOperation                 AS BusinessOperation
	|
	|FROM
	|	Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &Status NOT IN (
	|		VALUE(Enum.EmployeeApplicationStatuses.IsRejected),
	|		VALUE(Enum.EmployeeApplicationStatuses.Withdrawn)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&RequiredPaymentDate                          AS Period,
	|	&BusinessOperation                           AS BusinessOperation,
	|	&Organization                                     AS Organization,
	|	&Department                                   AS Department,
	|	CASE DocumentData.Ref.PaymentMethodOfPaymentRequest
	|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|			DocumentData.Ref.CashAccount
	|		ELSE
	|			DocumentData.Ref.BankAccount
	|	END AS Cash,
	|	CASE DocumentData.Ref.PaymentMethodOfPaymentRequest
	|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|			VALUE(Enum.CashTypes.CashPayment)
	|		WHEN VALUE(Enum.PaymentForms.BankAccountPayment) THEN
	|			VALUE(Enum.CashTypes.BankAccountPayments_)
	|		ELSE
	|			UNDEFINED
	|	END AS CashType,
	|	DocumentData.CashFlowItem    AS CashFlowItem,
	|	DocumentData.Ref.Currency                    AS Currency,
	|	DocumentData.Employee                        AS CorCash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CorCashType,
	|	DocumentData.Ref.Currency                    AS CorrespondingCurency,
	|	CASE
	|		WHEN NOT DocumentData.Ref.OverLimits THEN
	|			DocumentData.Sum
	|		ELSE
	|			0
	|	END AS AmountToBePaidWithinLimit,
	|	CASE
	|		WHEN DocumentData.Ref.OverLimits THEN
	|			DocumentData.Sum
	|		ELSE
	|			0
	|	END AS AmountToBePaidAboveLimit,
	|	CASE DocumentData.Ref.PaymentMethodOfPaymentRequest
	|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
	|			DocumentData.Ref.CashAccount
	|		ELSE
	|			DocumentData.Ref.BankAccount
	|	END                                            AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED                                     AS CorSourceOfFAGOfCash,
	|	&Ref AS PaymentRequest
	|FROM
	|	Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &Status NOT IN (
	|		VALUE(Enum.EmployeeApplicationStatuses.IsRejected),
	|		VALUE(Enum.EmployeeApplicationStatuses.Withdrawn)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlowLimits(Query, QueryTexts, Registers)
	
	RegisterName = "CashFlowLimits";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);

	QueryText = "
	|SELECT
	|	DocumentData.LineNumber AS ApplicationLineNumber,
	|	0 AS StatementLineNumber,
	|	
	|	CASE WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
	|		BEGINOFPERIOD(&RequiredPaymentDate, MONTH)
	|	ELSE
	|		BEGINOFPERIOD(&Period, MONTH)
	|	END AS Period,
	|	
	|	CASE
	|		WHEN &UseExpenseLimitsForOrganizations
	|			THEN &Organization 
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS Organization,
	|	CASE
	|		WHEN &UseExpenseLimitsByDivision
	|			THEN &Department 
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	
	|	CASE
	|		WHEN NOT &OverLimits
	|			THEN DocumentData.Sum * &ConversionRateToManCurrency
	|		ELSE 0
	|	END AS ConsumptionWithinLimit,
	|	
	|	CASE
	|		WHEN &OverLimits
	|			THEN DocumentData.Sum * &ConversionRateToManCurrency
	|		ELSE 0
	|	END AS ExcessExpense
	|
	|FROM
	|	Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UseCashFlowLimits
	|	AND &Status NOT IN (
	|		VALUE(Enum.EmployeeApplicationStatuses.IsRejected),
	|		VALUE(Enum.EmployeeApplicationStatuses.Withdrawn)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	&Partner                                AS Partner,
	|	&BankAccount                         AS StorageLocation,
	|	&Employee                              AS Counterparty,
	|	&Department                          AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	
	|	&Number                                  AS IBDocumentNumber,
	|	&Status                                 AS Status,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	UNDEFINED                            AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.ApplicationForBusinessTrip AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency") Then
		Return;
	EndIf;
	
	ConversionRateToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		Query.Parameters.Currency, Constants.ManagementAccountingCurrency.Get(), Query.Parameters.Period);
	
	Query.SetParameter("ConversionRateToManCurrency", ConversionRateToManCurrency);
	
EndProcedure

#EndRegion

#Region FillType

Function QueryTextBooking()
	
	QueryText = "
	|SELECT
	|	DocumentData.Organization                                         AS Organization,
	|	DocumentData.Department                                       AS Department,
	|	DocumentData.Employee                                           AS Employee,
	|	DocumentData.Currency                                              AS Currency,
	|	&Ref                                                             AS DocumentBasis
	|FROM
	|	Document.ApplicationForBusinessTrip AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.EmployeeApplicationStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.ApplicationForBusinessTrip AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the "Application for a business trip" document
	
EndFunction

Function CashFlowArticleOfDocument(DocumentData)
	
	If ValueIsFilled(DocumentData.CashFlowItem) Then
		CashFlowItem = DocumentData.CashFlowItem;
	Else
		CashFlowItem = Catalogs.CashFlowReportItems.PredefinedCFItem(
			Enums.BusinessTransactions.IssueCashToAdvanceHolder, DocumentData.Currency);
	EndIf;
	
	Return CashFlowItem;
	
EndFunction

#EndRegion
#Region ControllingLimitsBasedOnBudgetingData

// Returns the Query Text for creating a temporary table with data sources for rules for getting actual data on budget items.
// Data sources depend on the business of operation of the document.
//
// Returns:
//  String - Query text
//
Function QueryTextDataSourcesOfRulesForObtainingFact() Export
	
	QueryText = 
	"SELECT
	|	BusinessTransactionsSettings.Ref AS DataSource,
	|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Receipt AS Receipt,
	|	BusinessTransactionsSettings.Expense AS Expense
	|INTO DataSourcesOfRulesForObtainingFact
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|WHERE
	|	BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)";
	
	Return QueryText;
	
EndFunction

// Returns the Query Text as the source of actual data for the document.
// The source of actual data depends on the types of accounting data of operation rules for obtaining actual data on budget items.
//
// Parameters:
//  Expense - EnumRef.AccountingDataTypes - Business expense of operation
//  Receipt - EnumRef.AccountingDataTypes - Business Receipt of operation
//  TempTableName - String - name of the temp table (if not specified, the temp table is not generated)
//
// Returns:
//  String - Query text
//
Function QueryTextFactSourceByTypeOfAccountingData(Expense, Receipt, TempTableName = "") Export
	
	QueryText = "";
	
	If Expense = Enums.AccountingDataTypes.Cash
		And Receipt = Enums.AccountingDataTypes.Cash Then
		
		QueryText =
		"SELECT
		|	DataTable.RequiredPaymentDate AS Period,
		|	DataTable.Ref AS Recorder,
		|	VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AS DataSource,
		|	DataTable.Organization AS Organization,
		|	DataTable.Department AS Department,
		|	DataTable.Department AS PaymentDivision,
		|	UNDEFINED AS LineOfBusiness,
		|	CASE DataTable.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DataTable.CashAccount
		|		ELSE DataTable.BankAccount
		|	END AS Cash,
		|	CASE DataTable.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN VALUE(Enum.PaymentForms.BankAccountPayment)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE UNDEFINED
		|	END AS CashType,
		|	TableOutputForReport.CashFlowItem AS CashFlowItem,
		|	DataTable.Currency AS Currency,
		|	UNDEFINED AS CorLineOfBusiness,
		|	TableOutputForReport.Employee AS CorCash,
		|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CorCashType,
		|	DataTable.Currency AS CorrespondingCurency,
		|	CASE
		|		WHEN NOT DataTable.OverLimits
		|			THEN TableOutputForReport.Sum
		|		ELSE 0
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DataTable.OverLimits
		|			THEN TableOutputForReport.Sum
		|		ELSE 0
		|	END AS AmountToBePaidAboveLimit,
		|	TableOutputForReport.Sum AS AmountToBePaid
		|INTO TempTableName
		|FROM
		|	Document.ApplicationForBusinessTrip AS DataTable
		|		INNER JOIN Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS TableOutputForReport
		|		ON DataTable.Ref = TableOutputForReport.Ref
		|WHERE
		|	NOT DataTable.Status IN (VALUE(Enum.EmployeeApplicationStatuses.IsRejected), VALUE(Enum.EmployeeApplicationStatuses.Withdrawn))
		|	AND DataTable.Ref = &Document
		|	AND DataTable.RequiredPaymentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod";
		
	ElsIf Expense = Enums.AccountingDataTypes.Products
		And Receipt = Enums.AccountingDataTypes.IncomeExpenses Then
		
		QueryText =
		"SELECT
		|	ExpensesTable.PlannedExpenseDate AS Period,
		|	DataTable.Ref AS Recorder,
		|	DataTable.Organization AS Organization,
		|	DataTable.Department AS Department,
		|	DataTable.Department AS IncomeExpenseBusinessUnit,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	ExpensesTable.LineOfBusiness AS LineOfBusinessOfIncomeExpenses,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	ExpensesTable.BudgetFlowItem AS BudgetFlowItem,
		|	ExpensesTable.ExpenseItem AS IncomeAndExpenseItem,
		|	ExpensesTable.DimensionOfExpenses AS DimensionOfExpenses,
		|	DataTable.Currency AS Currency,
		|	ExpensesTable.Sum AS Sum,
		|	ExpensesTable.SumReal AS SumReal
		|INTO TempTableName
		|FROM
		|	Document.ApplicationForBusinessTrip AS DataTable
		|		INNER JOIN Document.ApplicationForBusinessTrip.Expenses AS ExpensesTable
		|		ON DataTable.Ref = ExpensesTable.Ref
		|WHERE
		|	NOT DataTable.Status IN (VALUE(Enum.EmployeeApplicationStatuses.IsRejected), VALUE(Enum.EmployeeApplicationStatuses.Withdrawn))
		|	AND DataTable.Ref = &Document
		|	AND ExpensesTable.PlannedExpenseDate BETWEEN &BeginOfPeriod AND &EndOfPeriod";
		
	EndIf;
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO TempTableName", "");
		QueryText = StrReplace(QueryText, "DataTable.Ref = &Document", "DataTable.Posted");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion
#Region InfobaseUpdate

// Adds information security update procedures to the list for all supported library versions or configurations.
// 
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.ApplicationForBusinessTrip.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.45";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("55fc8b34-5135-4b0b-acf7-9f6e221c19e2");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.ApplicationForBusinessTrip.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền dòng đầu tiên của phần bảng ""Chi phí"".';
							|ru = 'Заполняет первую строку табличной части ""Расходы"".';
							|en = 'Fills in the first row of the ""Expenses"" table.'; fa = 'Fills in the first row of the ""Expenses"" table.';
							|it = 'Fills in the first row of the ""Expenses"" table.';
							|pl = 'Fills in the first row of the ""Expenses"" table.';
							|tr = '""Giderler"" tablo bölümünün ilk satırını doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ApplicationForBusinessTrip.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.ApplicationForBusinessTrip.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.ApplicationForBusinessTrip.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.ApplicationForBusinessTrip";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ApplicationForBusinessTrip.Ref AS Ref
	|FROM
	|	Document.ApplicationForBusinessTrip AS ApplicationForBusinessTrip
	|		LEFT JOIN Document.ApplicationForBusinessTrip.Expenses AS ApplicationForBusinessTripExpenses
	|		ON ApplicationForBusinessTrip.Ref = ApplicationForBusinessTripExpenses.Ref
	|WHERE
	|	ApplicationForBusinessTrip.ExpectedExpenseAmount <> 0
	|	AND ApplicationForBusinessTripExpenses.Ref IS NULL
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.ApplicationForBusinessTrip";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = Selection.Ref.GetObject();
			NewRow = DocumentObject.Expenses.Add();
			NewRow.PlannedExpenseDate = DocumentObject.EndDate;
			NewRow.Sum = DocumentObject.ExpectedExpenseAmount;
			NewRow.ExpenseComment = DocumentObject.ExpenseComment;
			
			InfobaseUpdate.WriteData(DocumentObject);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf