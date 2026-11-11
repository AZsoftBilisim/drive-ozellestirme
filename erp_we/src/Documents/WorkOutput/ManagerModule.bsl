#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("WIPAccounting");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.WorkOutput") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableWIPLaborCosts(Query, QueryTexts, Registers);
		QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// Adds a command creation of the document "Development of employees".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined, ValueTableRow - description of the added command
//
Function AddCreateCommandBasedOnCreatingNewEmployees(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.WorkOutput) Then
		CreateBasedOnCommand						= GenerationCommands.Add();
		CreateBasedOnCommand.Handler			= "GenerationByReferenceTMClient.CreatingNewEmployees";
		CreateBasedOnCommand.Manager				= "Document.WorkOutput";
		CreateBasedOnCommand.Id			= "CreatingNewEmployees";
		CreateBasedOnCommand.Presentation			= NStr("vi = 'Sản lượng của nhân viên';
															|ru = 'Выработка сотрудников';
															|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
															|it = 'Produttività dei dipendenti';
															|pl = 'Ustawienia wydajności pracowników';
															|tr = 'Zaman çizelgesi bazlı ücretlendirme'");
		CreateBasedOnCommand.WriteMode			= "Post";
		CreateBasedOnCommand.FunctionalOptions	= "UseProduction,UseRMManagement,UseAccountingOfOtherIncomeExpenses";
		CreateBasedOnCommand.MultipleChoice	= True;
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Generates documents on employee Development for the period for the transferred organizations. Performs diagnostics and registers
// the problem if not all orders are processed. Called from the shape of the end of the month.
//
// Parameters:
//   HandlerParameters - Structure - parameters for closing the month.
//
Procedure IssueAtEndOfMonth(HandlerParameters) Export
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Organization", HandlerParameters.CalculationParameters.CompanyArray);
	FilterStructure1.Insert("BeginOfPeriod", BegOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod));
	FilterStructure1.Insert("EndOfPeriod", EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod));
	FilterStructure1.Insert("IncludeInPeriodOfWork", True);
	
	AddressInStorage = PutToTempStorage(Undefined);
	GenerateDocuments(FilterStructure1, AddressInStorage, True);
	Result = GetFromTempStorage(AddressInStorage);
	
	For Each String In Result.ErrorList Do 
		
		RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
			Catalogs.MonthEndClosingOperations.RegisterWorkOutput,
			String.Organization,
			BegOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod));
		
		MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
			RegistrationParameters,
			NStr("vi = 'Nên phát hành thủ công từ danh sách để thiết kế. Tự động chẩn đoán lỗi';
				|ru = 'Рекомендуется оформить вручную из списка к оформлению. При автоматическом оформлении диагностированы ошибки';
				|en = 'It is recommended that you register it manually from the list for registration. Errors were found during automatic registration'; fa = 'It is recommended that you register it manually from the list for registration. Errors were found during automatic registration';
				|it = 'Si consiglia di formalizzare manualmente dall''elenco per la formalizzazione. Durante la formalizzazione automatica sono stati diagnosticati gli errori';
				|pl = 'Zaleca się zarejestrować ręcznie z listy do sporządzenia. Podczas automatycznego sporządzenia wykryto błędy';
				|tr = 'Düzenleme için listeden manuel olarak düzenlemeniz önerilmektedir. Otomatik düzenleme sırasında sorun giderme hataları'", Common.DefaultLanguageCode()),
			,
			String.ErrorText);
			
	EndDo;
	
EndProcedure

// Generates documents based on the submitted selection and places them in a secure storage
// 
// Parameters:
// 	FilterStructure1 - Structure - LongDesc:
// * Organization - CatalogRef.Companies - selection of the organization
// * Department - CatalogRef.BusinessStructure - selection by division
// * WorkOrderKind - EnumRef.TeamWorkOrderKinds - selection by type of outfit
// * Team - CatalogRef.Teams - the selection of the team
// * BeginOfPeriod - Date
// 	ResultAddress - String - address where service information is placed: list of errors and number of documents
// 	DeleteDocumentsWithErrors - Boolean- if True, the documents that failed to be processed are deleted
//
Procedure GenerateDocuments(FilterStructure1, ResultAddress, DeleteDocumentsWithErrors = Undefined) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.WorkOutput.ManagerModule.GenerateDocuments");
	
	Result = New Structure;
	
	DocumentsList = New ValueList;
	ErrorList = New Array;
	
	HeaderStructure_ = New Structure("Team,WorkOrderKind,Organization,BeginOfPeriod,EndOfPeriod,Department");
	CurrentDocument = Undefined;
	
	Selection = LaborCostsToRegister(FilterStructure1).Select();
	
	While Selection.Next() Do
		
		If (HeaderStructure_.Team <> Selection.Team And ValueIsFilled(Selection.Team))
			Or HeaderStructure_.WorkOrderKind <> Selection.WorkOrderKind
			Or HeaderStructure_.Organization <> Selection.Organization
			Or HeaderStructure_.BeginOfPeriod <> Selection.BeginOfPeriod
			Or HeaderStructure_.EndOfPeriod <> Selection.EndOfPeriod
			Or HeaderStructure_.Department <> Selection.Department Then
			
			FillPropertyValues(HeaderStructure_, Selection);
			
			SaveNewDocument(CurrentDocument, DocumentsList, ErrorList);
			
			CurrentDocument = Documents.WorkOutput.CreateDocument();
			CurrentDocument.GetNewObjectRef();
			
			CurrentDocument.Fill(Selection);
			
			If FilterStructure1.Property("IncludeInPeriodOfWork") 
				And FilterStructure1.IncludeInPeriodOfWork Then
				CurrentDocument.Date = Selection.EndOfPeriod;
				CurrentDocument.Month = BegOfMonth(Selection.WorkExecutionDate);
			Else
				CurrentDocument.Date = CurrentSessionDate();
				CurrentDocument.Month = BegOfMonth(CurrentSessionDate());
			EndIf;
			
			CurrentDocument.AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentDocument.Month);
			
		EndIf;
		
		NewRow = CurrentDocument.ActivityKinds.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
	SaveNewDocument(CurrentDocument, DocumentsList, ErrorList);
	
	If DeleteDocumentsWithErrors = True Then
		
		ProcessedDocuments = New Map;
		For Each String In ErrorList Do
			
			If String.ErrorType = "DocumentExists"
				Or Not ProcessedDocuments[String.Document] = Undefined Then
				Continue;
			EndIf;
			
			ProcessedDocuments.Insert(String.Document, True);
			
			BeginTransaction();
			
			Try
				
				Block = New DataLock;
				LockItem = Block.Add("Document.WorkOutput");
				LockItem.SetValue("Ref", String.Document);
				LockItem.Mode = DataLockMode.Exclusive;
				
				Block.Lock();
				DocumentObject = String.Document.GetObject(); // DocumentObject.WorkOutput
				DocumentObject.Delete();
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				AddAutomaticCreationError(DocumentObject, ErrorList, "FillType", ErrorDescription());
				
			EndTry;
			
		EndDo;
		
	EndIf;
	
	GetUserMessages(True);
	
	Owner = Users.AuthorizedUser();
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Owner, DocumentsList.UnloadValues(), "EmployeeDevelopmentForm");
	SetPrivilegedMode(False);
	
	Result.Insert("ErrorList", ErrorList);
	Result.Insert("DocumentsCount", DocumentsList.Count());
	PutToTempStorage(Result, ResultAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, DocumentsList.Count());
	
EndProcedure

// Fills in the table of completed work on the remaining balance for registration in accordance with the selection.
//
// Parameters:
//  Object			- DocumentObject.WorkOutput, FormDataStructure - the document that you want to fill
//  FilterStructure1 - Structure - the structure of the padding settings.
//
Procedure FillOutTypesOfWorkOnBalances(Object, FilterStructure1) Export
	
	ToRegister = LaborCostsToRegister(FilterStructure1);
	
	Object.ActivityKinds.Load(ToRegister.Unload());
	
EndProcedure

// Returns the result of the request for the remaining labor costs to be processed in accordance with the selection.
//
// Parameters:
// 	FilterStructure1	- Structure - LongDesc:
// * Organization	- CatalogRef.Companies - selection of the organization
// * Departments	- CatalogRef.BusinessStructure - selection by division
// * WorkOrderKind		- EnumRef.TeamWorkOrderKinds - selection by type of outfit
// * Team		- CatalogRef.Teams - the selection of the team
// * Employee_		- CatalogRef.Persons - the selection of the team
// * Employee		- CatalogRef - selection by employees
// * EmployeesHR		- Array of CatalogRef - selection by employees
// * References	- Array - selection by order
// * ActivityKinds		- Array - selection by type of work
//	TempTablesManager	- TempTablesManager - Manager, if the result needs to be placed in a temporary table.
//
// Returns:
// 	QueryResult   - labor costs for registration.
//
Function LaborCostsToRegister(FilterStructure1, TempTablesManager = Undefined) Export
	
	Var Companies, Departments, Teams, Employees, WorkOrderKinds, References, ActivityKinds,
		TimeIntervals, BeginOfPeriod, EndOfPeriod, Periodicity, CollapseOrders;
	
	If FilterStructure1.Property("Organization") And ValueIsFilled(FilterStructure1.Organization) Then
		If TypeOf(FilterStructure1.Organization) = Type("Array") Then
			Companies = FilterStructure1.Organization;
		Else
			Companies = New Array;
			Companies.Add(FilterStructure1.Organization);
		EndIf;
	ElsIf Not FilterStructure1.Property("Companies", Companies) Then
		Companies = New Array;
	EndIf;
	
	If FilterStructure1.Property("Department") And ValueIsFilled(FilterStructure1.Department) Then
		Departments = New Array;
		Departments.Add(FilterStructure1.Department);
	ElsIf Not FilterStructure1.Property("Departments", Departments) Then
		Departments = New Array;
	EndIf;
	
	If FilterStructure1.Property("WorkOrderKind") Then
		WorkOrderKinds = New Array;
		WorkOrderKinds.Add(FilterStructure1.WorkOrderKind);
	ElsIf Not FilterStructure1.Property("WorkOrderKinds", WorkOrderKinds) Then
		WorkOrderKinds = New Array;
	EndIf;
	
	If FilterStructure1.Property("Team") And ValueIsFilled(FilterStructure1.Team) Then
		Teams = New Array;
		Teams.Add(FilterStructure1.Team);
	ElsIf Not FilterStructure1.Property("Teams", Teams) Then
		Teams = New Array;
	EndIf;
	
	If FilterStructure1.Property("Employee_") And ValueIsFilled(FilterStructure1.Employee_) Then
		Employees = New Array;
		Employees.Add(FilterStructure1.Employee_);
	ElsIf Not FilterStructure1.Property("Employees", Employees) Then
		Employees = New Array;
	EndIf;
	
	If FilterStructure1.Property("Employee") And ValueIsFilled(FilterStructure1.Employee) Then
		Employees.Add(FilterStructure1.Employee);
	ElsIf FilterStructure1.Property("EmployeesHR") Then
		For Each Employee In FilterStructure1.EmployeesHR Do
			Employees.Add(Employee);
		EndDo;
	EndIf;
	
	If Not FilterStructure1.Property("References", References) Then
		References = New Array;
	EndIf;
	
	If Not FilterStructure1.Property("ActivityKinds", ActivityKinds) Then
		ActivityKinds = New Array;
	EndIf;
	
	If Not FilterStructure1.Property("TimeIntervals", TimeIntervals) Then
		TimeIntervals = New Array;
	EndIf;
	
	If Not FilterStructure1.Property("BeginOfPeriod", BeginOfPeriod) Then
		BeginOfPeriod = Date(1,1,1);
	EndIf;
	
	If Not FilterStructure1.Property("EndOfPeriod", EndOfPeriod) Then
		EndOfPeriod = Date(3999,1,1);
	EndIf;
	
	If Not FilterStructure1.Property("Periodicity", Periodicity) Then
		Periodicity = Enums.FrequencyOfWorkOutputRegistration.EmptyRef();
	EndIf;
	
	If Not FilterStructure1.Property("CollapseOrders", CollapseOrders) Then
		CollapseOrders = False;
	EndIf;
	
	Query = New Query;
	
	If TempTablesManager <> Undefined Then
		Query.TempTablesManager = TempTablesManager;
	Else
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	If FilterStructure1.Property("DocumentException") Then
		Query.SetParameter("DocumentException", FilterStructure1.DocumentException);
	Else
		Query.SetParameter("DocumentException", Undefined);
	EndIf;
	
	If FilterStructure1.Property("IncludeInPeriodOfWork") Then
		Query.SetParameter("IncludeInPeriodOfWork", FilterStructure1.IncludeInPeriodOfWork);
	Else
		Query.SetParameter("IncludeInPeriodOfWork", True);
	EndIf;
	
	StructuralSelection = New ValueTable();
	StructuralSelection.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	StructuralSelection.Columns.Add("WorkOrderKind", New TypeDescription("EnumRef.TeamWorkOrderKinds"));
	StructuralSelection.Columns.Add("Team", New TypeDescription("CatalogRef.Teams"));
	
	If FilterStructure1.Property("StructuralSelection") Then
		
		For Each Structure In FilterStructure1.StructuralSelection Do
			String = StructuralSelection.Add();
			FillPropertyValues(String, Structure);
		EndDo;
		
		Query.SetParameter("WithoutSelectionByTypeOfOutfitsAndDivisions", Not ValueIsFilled(FilterStructure1.StructuralSelection));
	Else
		Query.SetParameter("WithoutSelectionByTypeOfOutfitsAndDivisions", True);
	EndIf;
	
	Query.SetParameter("StructuralSelection", StructuralSelection);
	
	Query.SetParameter("Companies",                   Companies);
	Query.SetParameter("NoSelectionByOrganization",       Companies.Count() = 0);
	
	Query.SetParameter("Departments",                 Departments);
	Query.SetParameter("NoSelectionByDivision",     Departments.Count() = 0);
	
	Query.SetParameter("WorkOrderKinds",                   WorkOrderKinds);
	Query.SetParameter("NoSelectionByOutfitType",       WorkOrderKinds.Count() = 0);
	
	Query.SetParameter("Teams",                       Teams);
	Query.SetParameter("WithoutSelectionByBrigades",           Teams.Count() = 0);
	
	Query.SetParameter("Employees",                     Employees);
	Query.SetParameter("NoEmployeeSelection",         Employees.Count() = 0);
	
	Query.SetParameter("TimeIntervals",                       TimeIntervals);
	Query.SetParameter("NoSelectionByPeriod",           TimeIntervals.Count() = 0);
	
	Query.SetParameter("References",                  References);
	Query.SetParameter("WithoutSelectionByOrder",      References.Count() = 0);
	
	Query.SetParameter("ActivityKinds",                     ActivityKinds);
	Query.SetParameter("WithoutSelectionByTypeOfWork",         ActivityKinds.Count() = 0);
	
	Query.SetParameter("BeginOfPeriod",                 BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",                  EndOfPeriod);
	
	Query.SetParameter("Periodicity",                 Periodicity);
	Query.SetParameter("CollapseOrders",       CollapseOrders);
	
	Query.SetParameter("AnalyticalAccountingByProductsGroups", GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	Query.SetParameter("StoreOperationsInBillsOfMaterials", GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
	Query.SetParameter("AccountingForLaborCostsByEmployees", ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(
		?(ValueIsFilled(BeginOfPeriod), BeginOfPeriod, CurrentSessionDate())));
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	UseLaborGradesOfEmployeeActivityRates = True;
	UseLaborGradesOfEmployeeActivityRates = GetFunctionalOption("UseLaborGradesOfEmployeeActivityRates");
	Query.SetParameter("UseLaborGradesOfEmployeeActivityRates", UseLaborGradesOfEmployeeActivityRates);
	
	
	#Region Balance
	
	QueryText = "
	|SELECT ALLOWED
	|	DD.Organization AS Organization,
	|	DD.ProductionLot AS ProductionLot,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	DD.WorkKind AS WorkKind,
	|	DD.Department AS Department,
	|	DD.Performer AS Performer,
	|	SUM(DD.CountReceipt - DD.CountExpense) AS CountTurnover
	|INTO Turnovers
	|FROM
	|	AccumulationRegister.LaborCostsToRegister.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,,
	|			(&NoSelectionByOrganization
	|					OR Organization IN (&Companies))
	|				AND (&WithoutSelectionByOrder
	|					OR ReferenceOrder IN (&References))
	|				AND (&WithoutSelectionByTypeOfWork
	|					OR WorkKind IN (&ActivityKinds))
	|				AND (&NoSelectionByDivision
	|					OR Department IN (&Departments))
	|				AND (&WithoutSelectionByBrigades
	|					OR Performer IN (&Teams)
	|					OR VALUETYPE(Performer) IN(
	|							TYPE(Catalog.EmployeesHR),
	|							TYPE(Catalog.Persons)))
	|				AND (&NoEmployeeSelection
	|					OR Performer IN (&Employees)
	|					OR VALUETYPE(Performer) = TYPE(Catalog.Teams))
	|	) AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.ProductionLot,
	|	DD.ReferenceOrder,
	|	DD.ReferenceRowCode,
	|	DD.WorkKind,
	|	DD.Department,
	|	DD.Performer
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot,
	|	ReferenceOrder,
	|	ReferenceRowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// We will receive orders according to which corrections were made with the preservation of the Lot reference of production.
	// If there were no corrections, then the amount for registration is obtained by actual Balances,
	// if there were, then by turnover for the period.
	|SELECT ALLOWED
	|	Turnovers.Organization           AS Organization,
	|	Turnovers.ProductionLot    AS ProductionLot,
	|	Turnovers.ReferenceOrder          AS ReferenceOrder,
	|	Turnovers.ReferenceRowCode AS ReferenceRowCode
	|INTO OrdersWithCorrection
	|FROM
	|	Turnovers AS Turnovers
	|	
	|	INNER JOIN Document.BackflushProduction AS AttributesBP
	|	ON AttributesBP.Ref = Turnovers.ReferenceOrder
	|	AND AttributesBP.CorrectionSavesProductionLots
	|	
	|	INNER JOIN AccumulationRegister.LaborCostsToRegister AS LaborCostsToRegister
	|	ON LaborCostsToRegister.Organization = Turnovers.Organization
	|	AND LaborCostsToRegister.ProductionLot = Turnovers.ProductionLot
	|	AND LaborCostsToRegister.ReferenceOrder = Turnovers.ReferenceOrder
	|	AND LaborCostsToRegister.ReferenceRowCode = Turnovers.ReferenceRowCode
	|	
	|	INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsStorno
	|	ON DocumentsStorno.Ref = LaborCostsToRegister.Recorder
	|	AND DocumentsStorno.ReverseTransactionCorrection
	|	AND DocumentsStorno.Posted
	|	AND NOT DocumentsStorno.AdditionalRecord
	|
	|WHERE
	|	NOT LaborCostsToRegister.Count = 0
	|
	|GROUP BY
	|	Turnovers.Organization,
	|	Turnovers.ProductionLot,
	|	Turnovers.ReferenceOrder,
	|	Turnovers.ReferenceRowCode
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot,
	|	ReferenceOrder,
	|	ReferenceRowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	LaborCostsToRegister.Periodicity AS Periodicity,
	|	LaborCostsToRegister.WorkKind AS WorkKind,
	|	LaborCostsToRegister.Organization AS Organization,
	|	LaborCostsToRegister.ReferenceOrder AS ReferenceOrder,
	|	LaborCostsToRegister.Performer AS Performer,
	|	LaborCostsToRegister.Department AS Department,
	|	LaborCostsToRegister.ReferenceRowCode AS ReferenceRowCode,
	|	LaborCostsToRegister.Status AS Status,
	|	MAX(LaborCostsToRegister.ThereAreFixes) AS ThereAreFixes,
	|	SUM(LaborCostsToRegister.Count) AS Count
	|INTO Balance
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN &Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.EmptyRef)
	|				THEN CatDepartments.OutputRegistrationFrequency
	|			ELSE &Periodicity
	|		END AS Periodicity,
	|		LaborCostsToRegister.WorkKind AS WorkKind,
	|		LaborCostsToRegister.CountBalance AS Count,
	|		LaborCostsToRegister.Organization AS Organization,
	|		LaborCostsToRegister.ReferenceOrder AS ReferenceOrder,
	|		LaborCostsToRegister.Performer AS Performer,
	|		LaborCostsToRegister.Department AS Department,
	|		LaborCostsToRegister.ReferenceRowCode AS ReferenceRowCode,
	|		CASE
	|			WHEN TRUE
	|				THEN LaborCostsToRegister.ReferenceOrder.Status
	|			WHEN TRUE
	|				THEN UNDEFINED
	|		END AS Status,
	|		FALSE AS ThereAreFixes
	|	FROM
	|		AccumulationRegister.LaborCostsToRegister.Balance(
	|			,
	|			(Organization, ReferenceOrder, WorkKind, Department, Performer) IN(
	|				SELECT
	|					Turnovers.Organization,
	|					Turnovers.ReferenceOrder,
	|					Turnovers.WorkKind,
	|					Turnovers.Department,
	|					Turnovers.Performer
	|				FROM
	|					Turnovers AS Turnovers)) AS LaborCostsToRegister
	|		
	|		INNER JOIN Catalog.BusinessStructure AS CatDepartments
	|		ON CatDepartments.Ref = LaborCostsToRegister.Department
	|		
	// We exclude orders with corrections.
	|		LEFT JOIN OrdersWithCorrection AS OrdersWithCorrection
	|		ON OrdersWithCorrection.Organization = LaborCostsToRegister.Organization
	|		AND OrdersWithCorrection.ProductionLot = LaborCostsToRegister.ProductionLot
	|		AND OrdersWithCorrection.ReferenceOrder = LaborCostsToRegister.ReferenceOrder
	|		AND OrdersWithCorrection.ReferenceRowCode = LaborCostsToRegister.ReferenceRowCode
	|		
	|	WHERE
	// We exclude orders with corrections.
	|		OrdersWithCorrection.ProductionLot IS NULL
	|	
	|	UNION ALL
	|	
	// Orders with corrections.
	|	SELECT
	|		CASE
	|			WHEN &Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.EmptyRef)
	|				THEN CatDepartments.OutputRegistrationFrequency
	|			ELSE &Periodicity
	|		END AS Periodicity,
	|		LaborCostsToRegister.WorkKind AS WorkKind,
	|		LaborCostsToRegister.CountTurnover AS Count,
	|		LaborCostsToRegister.Organization AS Organization,
	|		LaborCostsToRegister.ReferenceOrder AS ReferenceOrder,
	|		LaborCostsToRegister.Performer AS Performer,
	|		LaborCostsToRegister.Department AS Department,
	|		LaborCostsToRegister.ReferenceRowCode AS ReferenceRowCode,
	|		CASE
	|			WHEN TRUE
	|				THEN LaborCostsToRegister.ReferenceOrder.Status
	|			WHEN TRUE
	|				THEN UNDEFINED
	|		END AS Status,
	|		TRUE AS ThereAreFixes
	|	FROM
	|		Turnovers AS LaborCostsToRegister
	|		
	|		INNER JOIN Catalog.BusinessStructure AS CatDepartments
	|		ON CatDepartments.Ref = LaborCostsToRegister.Department
	|		
	|		INNER JOIN OrdersWithCorrection AS OrdersWithCorrection
	|		ON OrdersWithCorrection.Organization = LaborCostsToRegister.Organization
	|		AND OrdersWithCorrection.ProductionLot = LaborCostsToRegister.ProductionLot
	|		AND OrdersWithCorrection.ReferenceOrder = LaborCostsToRegister.ReferenceOrder
	|		AND OrdersWithCorrection.ReferenceRowCode = LaborCostsToRegister.ReferenceRowCode
	|	
	|	WHERE
	|		NOT LaborCostsToRegister.CountTurnover = 0
	|	
	|	UNION ALL
	|	
	// We restore the Balances by Registering Records of the current document
	|	SELECT
	|		CASE
	|			WHEN &Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.EmptyRef)
	|				THEN CatDepartments.OutputRegistrationFrequency
	|			ELSE &Periodicity
	|		END AS Periodicity,
	|		LaborCostsToRegister.WorkKind AS WorkKind,
	|		LaborCostsToRegister.Count AS Count,
	|		LaborCostsToRegister.Organization AS Organization,
	|		LaborCostsToRegister.ReferenceOrder AS ReferenceOrder,
	|		LaborCostsToRegister.Performer AS Performer,
	|		LaborCostsToRegister.Department AS Department,
	|		LaborCostsToRegister.ReferenceRowCode AS ReferenceRowCode,
	|		CASE
	|			WHEN TRUE
	|				THEN LaborCostsToRegister.ReferenceOrder.Status
	|			WHEN TRUE
	|				THEN UNDEFINED
	|		END AS Status,
	|		OrdersWithCorrection.ReferenceOrder IS NOT NULL AS ThereAreFixes
	|	FROM
	|		AccumulationRegister.LaborCostsToRegister AS LaborCostsToRegister
	|	
	|		INNER JOIN Catalog.BusinessStructure AS CatDepartments
	|		ON CatDepartments.Ref = LaborCostsToRegister.Department
	|	
	|		LEFT JOIN OrdersWithCorrection AS OrdersWithCorrection
	|		ON OrdersWithCorrection.Organization = LaborCostsToRegister.Organization
	|		AND OrdersWithCorrection.ProductionLot = LaborCostsToRegister.ProductionLot
	|		AND OrdersWithCorrection.ReferenceOrder = LaborCostsToRegister.ReferenceOrder
	|		AND OrdersWithCorrection.ReferenceRowCode = LaborCostsToRegister.ReferenceRowCode
	|	
	|	WHERE
	|		(&NoSelectionByOrganization
	|			OR LaborCostsToRegister.Organization IN (&Companies))
	|		AND (&WithoutSelectionByOrder
	|			OR LaborCostsToRegister.ReferenceOrder IN (&References))
	|		AND (&WithoutSelectionByTypeOfWork
	|			OR LaborCostsToRegister.WorkKind IN (&ActivityKinds))
	|		AND (&NoSelectionByDivision
	|			OR LaborCostsToRegister.Department IN (&Departments))
	|		AND (&WithoutSelectionByBrigades
	|			OR LaborCostsToRegister.Performer IN (&Teams)
	|			OR VALUETYPE(Performer) = TYPE(Catalog.Teams))
	|		AND (&NoEmployeeSelection
	|			OR LaborCostsToRegister.Performer IN (&Employees)
	|			OR VALUETYPE(Performer) = TYPE(Catalog.Teams))
	|		AND LaborCostsToRegister.Recorder = &DocumentException
	|	) AS LaborCostsToRegister
	|
	|GROUP BY
	|	LaborCostsToRegister.Periodicity,
	|	LaborCostsToRegister.WorkKind,
	|	LaborCostsToRegister.Organization,
	|	LaborCostsToRegister.ReferenceOrder,
	|	LaborCostsToRegister.Performer,
	|	LaborCostsToRegister.Department,
	|	LaborCostsToRegister.ReferenceRowCode,
	|	LaborCostsToRegister.Status
	|
	|INDEX BY
	|	ReferenceOrder
	|";
	
	Query.Text = QueryText;
	Query.Execute();
	
	#EndRegion
	
	#Region AuxiliaryData
	
	QueriesTexts = New Array;
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage IN (SELECT DISTINCT DD.ReferenceOrder.Stage FROM Balance AS DD)");
	RequestTextParameters.IndexingFields.Add("Stage");
	
	QueriesTexts.Add(InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters));
	
	QueryText = "
	|SELECT
	|	Queue.Department                                      AS Department,
	|	Queue.Stage                                               AS Stage,
	|	Queue.Operation                                           AS Operation,
	|	Queue.ProductionOperation                           AS ProductionOperation,
	|	Queue.OperationID                              AS OperationID,
	|	Queue.ControlOperationID                   AS ControlOperationID,
	|	Queue.Scheduled - Queue.RepetitionIsRequired          AS Scheduled,
	|	Queue.CreatedOn                                            AS CreatedOn,
	|	Queue.Completed2                                          AS Completed2,
	|	Queue.DefectiveGoods                                               AS DefectiveGoods
	|INTO PerformanceOfOperations
	|FROM
	|	TTQueue AS Queue
	|
	|UNION ALL
	|
	|SELECT
	|	Operations.Department                                      AS Department,
	|	Operations.Stage                                               AS Stage,
	|	Operations.Operation                                           AS Operation,
	|	CASE
	|		WHEN Operations.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|			THEN Operations.Ref
	|		ELSE VALUE(Document.ProductionOperation2_2.EmptyRef)
	|	END                                                       AS ProductionOperation,
	|	Operations.OperationID                              AS OperationID,
	|	MAX(Operations.ControlOperationID)         AS ControlOperationID,
	|	SUM(Operations.Count - Operations.CountCanceled)    AS Scheduled,
	|	SUM(Operations.Count - Operations.CountCanceled)    AS CreatedOn,
	|	SUM(Operations.CountReal)                              AS Completed2,
	|	SUM(Operations.DefectiveGoodsCount)                              AS DefectiveGoods
	|	
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|WHERE
	|	Operations.Posted
	|	AND Operations.Stage IN (
	|				SELECT DISTINCT
	|					DD.ReferenceOrder.Stage
	|				FROM Balance AS DD)
	|	AND NOT TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTQueue AS Queue
	|				WHERE
	|					Operations.Stage = Queue.Stage)
	|
	|GROUP BY
	|	Operations.Department,
	|	Operations.Stage,
	|	Operations.Operation,
	|	CASE
	|		WHEN Operations.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|			THEN Operations.Ref
	|		ELSE VALUE(Document.ProductionOperation2_2.EmptyRef)
	|	END,
	|	Operations.OperationID
	|
	|";
	QueriesTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN NOT LaborCostsToRegister.ThereAreFixes
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.Date
	|		WHEN LaborCostsToRegister.ThereAreFixes
	|			AND LaborCostsOfProductionWithoutOrder.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.Date
	|		ELSE &EndOfPeriod
	|	END                                               AS ExecutionDate,
	|	LaborCostsOfProductionWithoutOrder.ProductCostElement AS ProductCostElement,
	|	LaborCostsOfProductionWithoutOrder.Ref            AS ReferenceOrder,
	|	LaborCostsOfProductionWithoutOrder.RowCode         AS RowCode,
	|	CASE
	|		WHEN LaborCostsOfProductionWithoutOrder.Ref.Patch
	|			AND LaborCostsOfProductionWithoutOrder.Ref.CorrectionSavesProductionLots
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.CorrectedDocument
	|		ELSE LaborCostsOfProductionWithoutOrder.Ref
	|	END                                               AS DocumentLots,
	|	LaborCostsOfProductionWithoutOrder.CostGroupNumber AS CostGroupNumber
	|INTO TTBatchProductionWithoutOrderPreparatory
	|FROM
	|	Balance AS LaborCostsToRegister
	|	
	|	INNER JOIN Document.BackflushProduction.LaborCosts AS LaborCostsOfProductionWithoutOrder
	|	ON LaborCostsOfProductionWithoutOrder.Ref = LaborCostsToRegister.ReferenceOrder
	|	AND LaborCostsOfProductionWithoutOrder.RowCode = LaborCostsToRegister.ReferenceRowCode
	|
	|GROUP BY
	|	CASE
	|		WHEN LaborCostsOfProductionWithoutOrder.Ref.Patch
	|			AND LaborCostsOfProductionWithoutOrder.Ref.CorrectionSavesProductionLots
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.CorrectedDocument
	|		ELSE LaborCostsOfProductionWithoutOrder.Ref
	|	END,
	|	LaborCostsOfProductionWithoutOrder.Ref,
	|	LaborCostsOfProductionWithoutOrder.RowCode,
	|	LaborCostsOfProductionWithoutOrder.CostGroupNumber,
	|	LaborCostsOfProductionWithoutOrder.ProductCostElement,
	|	CASE
	|		WHEN NOT LaborCostsToRegister.ThereAreFixes
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.Date
	|		WHEN LaborCostsToRegister.ThereAreFixes
	|			AND LaborCostsOfProductionWithoutOrder.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.Date
	|		ELSE &EndOfPeriod
	|	END
	|
	|INDEX BY
	|	DocumentLots,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LaborCostsOfProductionWithoutOrder.ExecutionDate	AS ExecutionDate,
	|	LaborCostsOfProductionWithoutOrder.ProductCostElement	AS ProductCostElement,
	|	LaborCostsOfProductionWithoutOrder.ReferenceOrder		AS ReferenceOrder,
	|	LaborCostsOfProductionWithoutOrder.RowCode			AS ReferenceRowCode,
	|	CatProductionLots.ProductsGroup				AS ProductsGroup
	|INTO TTBatchProductionWithoutOrder
	|FROM
	|	TTBatchProductionWithoutOrderPreparatory AS LaborCostsOfProductionWithoutOrder
	|
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = LaborCostsOfProductionWithoutOrder.DocumentLots
	|	AND CatProductionLots.Code = LaborCostsOfProductionWithoutOrder.CostGroupNumber
	|	AND NOT CatProductionLots.DeletionMark
	|
	|GROUP BY
	|	LaborCostsOfProductionWithoutOrder.ReferenceOrder,
	|	LaborCostsOfProductionWithoutOrder.ExecutionDate,
	|	LaborCostsOfProductionWithoutOrder.ProductCostElement,
	|	LaborCostsOfProductionWithoutOrder.RowCode,
	|	CatProductionLots.ProductsGroup
	|
	|INDEX BY
	|	ReferenceOrder,
	|	ReferenceRowCode
	|;
	|
	|
	|SELECT
	|	Operations.Department         AS Department,
	|	Operations.Stage                  AS Stage,
	|	Operations.Operation              AS Operation,
	|	Operations.OperationID AS OperationID,
	|	Operations.Ref                AS Ref,
	|
	|	ISNULL(Operations.Operation.Owner, Operations.Ref)  AS OwnerOfTechnologicalOperation,
	|	ISNULL(Operations.Operation.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)) AS BillOfMaterialsOfProcessOfOperation,
	|	Operations.Stage.Stage                 AS BOMStage,
	|	Operations.Stage.ProductionLot   AS ProductionLot,
	|	Operations.ExecutionEnd       AS ExecutionDate,
	|
	|	Operations.Count - Operations.CountCanceled      AS Count,
	|	Operations.CountReal                                AS CountReal,
	|	Operations.DefectiveGoodsCount                                AS DefectiveGoodsCount,
	|
	|	ISNULL(Queue.ControlOperationID, -1) AS ControlOperationID,
	|	ISNULL(Queue.CreatedOn,   0)                         AS CreatedOn,
	|	ISNULL(Queue.Completed2, 0)                         AS Completed2,
	|	ISNULL(Queue.Scheduled, 0)                     AS Scheduled
	|
	|INTO ProductionOperations
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|	
	|	LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
	|	ON Operations.Department = Queue.Department
	|	AND Operations.Stage          = Queue.Stage
	|	AND Operations.Operation      = Queue.Operation
	|	AND Operations.OperationID = Queue.OperationID
	|
	|WHERE
	|	Operations.Ref IN (SELECT DD.ReferenceOrder FROM Balance AS DD)
	|
	|INDEX BY
	|	Department,
	|	Stage,
	|	Operation,
	|	OperationID,
	|	Ref
	|;
	|
	|SELECT
	|	Operations.ControlOperationID AS ControlOperationID,
	|	Operations.Department                    AS Department,
	|	Operations.Stage                             AS Stage,
	|	MAX(Operations.CreatedOn)                AS CreatedOn,
	|	MAX(Operations.Scheduled)          AS Scheduled
	|INTO IdsOfControlOperations
	|FROM
	|	ProductionOperations AS Operations
	|
	|WHERE
	|	Operations.ControlOperationID > 0
	|	AND Operations.ControlOperationID <> Operations.OperationID
	|
	|GROUP BY
	|	Operations.ControlOperationID,
	|	Operations.Department,
	|	Operations.Stage
	|
	|INDEX BY
	|	ControlOperationID,
	|	Department,
	|	Stage
	|;
	|
	|SELECT
	|	Operations.OperationID                           AS OperationID,
	|	Operations.Department                                   AS Department,
	|	Operations.Stage                                            AS Stage,
	|	SUM(Operations.Count - Operations.CountCanceled) AS Count,
	|	SUM(Operations.CountReal)                           AS CountReal
	|INTO ControlOperationsQuantitativeIndicators
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			IdsOfControlOperations AS IdsOfControlOperations
	|		WHERE
	|			IdsOfControlOperations.ControlOperationID = Operations.OperationID
	|			AND IdsOfControlOperations.Department                  = Operations.Department
	|			AND IdsOfControlOperations.Stage                           = Operations.Stage)
	|	AND Operations.Posted
	|	
	|GROUP BY
	|	Operations.OperationID,
	|	Operations.Department,
	|	Operations.Stage
	|	
	|INDEX BY
	|	OperationID,
	|	Department,
	|	Stage
	|;
	|
	|SELECT
	|
	|	Operations.ControlOperationID AS ControlOperationID,
	|	Operations.Department                    AS Department,
	|	Operations.Stage                             AS Stage,
	|
	|	ISNULL(CASE
	|			WHEN Operations.CreatedOn
	|					* CASE
	|						WHEN Operations.Scheduled = 0
	|							THEN 1
	|						ELSE Queue.Scheduled / Operations.Scheduled
	|					END < Queue.Scheduled
	|				AND Operations.CreatedOn
	|					* CASE
	|						WHEN Operations.Scheduled = 0
	|							THEN 1
	|						ELSE Queue.Scheduled / Operations.Scheduled
	|					END > (Queue.Completed2 + Queue.DefectiveGoods)
	|			OR Operations.CreatedOn
	|					* CASE
	|						WHEN Operations.Scheduled = 0
	|							THEN 1
	|						ELSE Queue.Scheduled / Operations.Scheduled
	|					END >= Queue.Scheduled
	|				AND Queue.Scheduled > (Queue.Completed2 + Queue.DefectiveGoods)
	|					THEN 0
	|			END, Queue.Completed2) AS Completed2,
	|	ISNULL(CASE
	|			WHEN Operations.CreatedOn
	|					* CASE
	|						WHEN Operations.Scheduled = 0
	|							THEN 1
	|						ELSE Queue.Scheduled / Operations.Scheduled
	|					END < Queue.Scheduled
	|				AND Operations.CreatedOn
	|					* CASE
	|						WHEN Operations.Scheduled = 0
	|							THEN 1
	|						ELSE Queue.Scheduled / Operations.Scheduled
	|					END > (Queue.Completed2 + Queue.DefectiveGoods)
	|			OR Operations.CreatedOn
	|					* CASE
	|						WHEN Operations.Scheduled = 0
	|							THEN 1
	|						ELSE Queue.Scheduled / Operations.Scheduled
	|					END >= Queue.Scheduled
	|				AND Queue.Scheduled > (Queue.Completed2 + Queue.DefectiveGoods)
	|					THEN 0
	|			END, Queue.DefectiveGoods)      AS DefectiveGoods,
	|
	|	ISNULL(ControlOperationsQuantitativeIndicators.Count, 0)     AS Count,
	|	ISNULL(ControlOperationsQuantitativeIndicators.CountReal, 0) AS CountReal
	|
	|INTO ControlOperations
	|FROM
	|	IdsOfControlOperations AS Operations
	|
	|		INNER JOIN PerformanceOfOperations AS Queue
	|		ON Operations.ControlOperationID = Queue.OperationID
	|		 AND Operations.Department                    = Queue.Department
	|		 AND Operations.Stage                             = Queue.Stage
	|
	|		LEFT JOIN ControlOperationsQuantitativeIndicators AS ControlOperationsQuantitativeIndicators
	|		ON Operations.ControlOperationID = ControlOperationsQuantitativeIndicators.OperationID
	|		 AND Operations.Department                    = ControlOperationsQuantitativeIndicators.Department
	|		 AND Operations.Stage                             = ControlOperationsQuantitativeIndicators.Stage
	|
	|INDEX BY
	|	ControlOperationID,
	|	Department,
	|	Stage
	|;
	|
	|DROP IdsOfControlOperations
	|
	|;
	|
	|SELECT
	|	NestedQuery.OwnerOfTechnologicalOperation AS OwnerOfTechnologicalOperation,
	|	NestedQuery.WorkKind                        AS WorkKind,
	|	MAX(NestedQuery.ProductCostElement)     AS ProductCostElement
	|INTO TTCalculationArticlesOnNSI
	|FROM
	|	(SELECT
	|		Operations.OwnerOfTechnologicalOperation,
	|		LaborCosts.ProductCostElement,
	|		LaborCosts.WorkKind
	|	FROM
	|		Catalog.RouteSheets.LaborCosts AS LaborCosts
	|
	|		INNER JOIN ProductionOperations AS Operations
	|		ON Operations.OwnerOfTechnologicalOperation = LaborCosts.Ref
	|		
	|	UNION ALL
	|
	|	SELECT
	|		Operations.OwnerOfTechnologicalOperation,
	|		LaborCosts.ProductCostElement,
	|		LaborCosts.WorkKind
	|	FROM
	|		Catalog.BillsOfMaterials.LaborCosts AS LaborCosts
	|
	|		INNER JOIN ProductionOperations AS Operations
	|		ON &StoreOperationsInBillsOfMaterials
	|			AND Operations.BillOfMaterialsOfProcessOfOperation = LaborCosts.Ref
	|			AND Operations.BOMStage = LaborCosts.Stage
	|	
	|	UNION ALL
	|
	|	SELECT
	|		Operations.OwnerOfTechnologicalOperation,
	|		LaborCosts.ProductCostElement,
	|		LaborCosts.WorkKind
	|	FROM
	|		Catalog.TechnologicalProcesses.LaborCosts AS LaborCosts
	|	
	|		INNER JOIN ProductionOperations AS Operations
	|		ON &StoreOperationsInBillsOfMaterials
	|			AND Operations.OwnerOfTechnologicalOperation = LaborCosts.Ref
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.OwnerOfTechnologicalOperation,
	|	NestedQuery.WorkKind
	|
	|HAVING
	|	COUNT(DISTINCT NestedQuery.ProductCostElement) = 1
	|
	|INDEX BY
	|	OwnerOfTechnologicalOperation,
	|	WorkKind
	|
	|;
	|
	|SELECT
	|	NestedQuery.ProductionOperation    AS ProductionOperation,
	|	NestedQuery.WorkKind                    AS WorkKind,
	|	MAX(NestedQuery.ProductCostElement) AS ProductCostElement
	|INTO TTOperationCalculationArticles
	|FROM 
	|	(SELECT
	|	LaborCosts.Ref            AS ProductionOperation,
	|	LaborCosts.WorkKind          AS WorkKind,
	|	LaborCosts.ProductCostElement AS ProductCostElement
	|FROM
	|	Document.ProductionOperation2_2.LaborCosts AS LaborCosts
	|	
	|	INNER JOIN ProductionOperations AS Operations
	|	ON Operations.Ref = LaborCosts.Ref
	|		AND NOT LaborCosts.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|		AND LaborCosts.Ref.BasedOnMasterData
	|	
	|	UNION ALL
	|
	|	SELECT
	|		Operations.OwnerOfTechnologicalOperation,
	|		LaborCosts.WorkKind,
	|		LaborCosts.ProductCostElement
	|	FROM
	|		Document.ProductionOperation2_2.LaborCosts AS LaborCosts
	|		
	|		INNER JOIN ProductionOperations AS Operations
	|		ON Operations.OwnerOfTechnologicalOperation = LaborCosts.Ref
	|			AND NOT LaborCosts.Ref.BasedOnMasterData
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ProductionOperation,
	|	NestedQuery.WorkKind
	|
	|HAVING
	|	COUNT(DISTINCT NestedQuery.ProductCostElement) = 1
	|
	|INDEX BY
	|	ProductionOperation,
	|	WorkKind
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN LaborCostsToRegister.Performer REFS Catalog.Teams
	|			THEN VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|		ELSE
	|			VALUE(Enum.TeamWorkOrderKinds.Personal)
	|	END											AS WorkOrderKind,
	|	BatchProductionWithoutOrder.ExecutionDate		AS ExecutionDate,
	|	LaborCostsToRegister.Periodicity			AS Periodicity,
	|	LaborCostsToRegister.ReferenceRowCode	AS ReferenceRowCode,
	|	LaborCostsToRegister.WorkKind				AS WorkKind,
	|	LaborCostsToRegister.Count				AS QuantityToRegister,
	|	LaborCostsToRegister.Count				AS AmountDueForPayment,
	|	LaborCostsToRegister.Organization				AS Organization,
	|	LaborCostsToRegister.ReferenceOrder			AS ReferenceOrder,
	|	LaborCostsToRegister.Performer				AS Performer,
	|	LaborCostsToRegister.Department			AS Department,
	|	BatchProductionWithoutOrder.ProductsGroup		AS ProductsGroup,
	|	BatchProductionWithoutOrder.ProductCostElement	AS ProductCostElement
	|INTO TTLaborCostsForRegistration
	|FROM
	|	Balance AS LaborCostsToRegister
	|
	|	INNER JOIN TTBatchProductionWithoutOrder AS BatchProductionWithoutOrder
	|	ON BatchProductionWithoutOrder.ReferenceOrder = LaborCostsToRegister.ReferenceOrder
	|	AND BatchProductionWithoutOrder.ReferenceRowCode = LaborCostsToRegister.ReferenceRowCode
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Enum.TeamWorkOrderKinds.Repair) AS WorkOrderKind,
	|	RMOrder.Date AS ExecutionDate,
	|	LaborCostsToRegister.Periodicity AS Periodicity,
	|	LaborCostsToRegister.ReferenceRowCode AS ReferenceRowCode,
	|	LaborCostsToRegister.WorkKind AS WorkKind,
	|	LaborCostsToRegister.Count AS QuantityToRegister,
	|	LaborCostsToRegister.Count AS AmountDueForPayment,
	|	LaborCostsToRegister.Organization AS Organization,
	|	LaborCostsToRegister.ReferenceOrder AS ReferenceOrder,
	|	LaborCostsToRegister.Performer AS Performer,
	|	LaborCostsToRegister.Department AS Department,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement
	|FROM
	|	Balance AS LaborCostsToRegister
	|	
	|	INNER JOIN Document.RMOrder AS RMOrder
	|	ON LaborCostsToRegister.ReferenceOrder = RMOrder.Ref
	|	
	|	LEFT JOIN Document.RMOrder.LaborCosts AS RepairOrderLaborCosts
	|	ON LaborCostsToRegister.ReferenceOrder = RepairOrderLaborCosts.Ref
	|	AND LaborCostsToRegister.ReferenceRowCode = RepairOrderLaborCosts.LineNumber
	|	
	|	LEFT JOIN Document.RMOrder.RM AS RMOrderRM
	|	ON RepairOrderLaborCosts.Ref = RMOrderRM.Ref
	|	AND RepairOrderLaborCosts.RMCode = RMOrderRM.RMCode
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN LaborCostsToRegister.Performer REFS Catalog.Teams
	|			THEN VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|		ELSE
	|			VALUE(Enum.TeamWorkOrderKinds.Personal)
	|	END AS WorkOrderKind,
	|	StageLaborCosts.ExecutionDate AS ExecutionDate,
	|	LaborCostsToRegister.Periodicity AS Periodicity,
	|	LaborCostsToRegister.ReferenceRowCode,
	|	LaborCostsToRegister.WorkKind,
	|	LaborCostsToRegister.Count,
	|	LaborCostsToRegister.Count,
	|	LaborCostsToRegister.Organization,
	|	LaborCostsToRegister.ReferenceOrder,
	|	LaborCostsToRegister.Performer,
	|	LaborCostsToRegister.Department,
	|	CatProductionLots.ProductsGroup AS ProductsGroup,
	|	StageLaborCosts.ProductCostElement AS ProductCostElement
	|FROM
	|	Balance AS LaborCostsToRegister
	|	
	|	INNER JOIN Document.ProductionStage2_2.LaborCosts AS StageLaborCosts
	|	ON StageLaborCosts.Ref = LaborCostsToRegister.ReferenceOrder
	|	AND StageLaborCosts.RowCode = LaborCostsToRegister.ReferenceRowCode
	|	AND NOT StageLaborCosts.Canceled
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.Ref = LaborCostsToRegister.ReferenceOrder
	|	
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = StageDetails.ProductionLot
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN LaborCostsToRegister.Performer REFS Catalog.Teams
	|			THEN VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|		ELSE
	|			VALUE(Enum.TeamWorkOrderKinds.Personal)
	|	END AS WorkOrderKind,
	|	Operations.ExecutionDate AS ExecutionDate,
	|	LaborCostsToRegister.Periodicity AS Periodicity,
	|	LaborCostsToRegister.ReferenceRowCode,
	|	LaborCostsToRegister.WorkKind,
	|	LaborCostsToRegister.Count
	|		* CASE
	|			WHEN Operations.Count > 0
	|				THEN (Operations.CountReal + Operations.DefectiveGoodsCount) / Operations.Count
	|			ELSE 0
	|		END                                                                                         AS QuantityToRegister,
	|	LaborCostsToRegister.Count
	|		* CASE
	|			WHEN Operations.Count = 0
	|				THEN 0
	|			ELSE Operations.CountReal / Operations.Count
	|		END
	|		* CASE
	|			WHEN Operations.OperationID = ControlOperations.ControlOperationID
	|			  OR ISNULL(ControlOperations.Count, 0) = 0
	|				THEN 1
	|			ELSE ControlOperations.CountReal / ControlOperations.Count
	|		END                                                                                         AS AmountDueForPayment,
	|	LaborCostsToRegister.Organization,
	|	LaborCostsToRegister.ReferenceOrder,
	|	LaborCostsToRegister.Performer,
	|	LaborCostsToRegister.Department,
	|	Operations.ProductionLot.ProductsGroup AS ProductsGroup,
	|	ISNULL(ArticlesOfCalculationOfOperations.ProductCostElement, NSICalculationArticles.ProductCostElement) AS ProductCostElement
	|FROM
	|	ProductionOperations AS Operations
	|	
	|	LEFT JOIN ControlOperations AS ControlOperations
	|	ON Operations.ControlOperationID = ControlOperations.ControlOperationID
	|	AND Operations.Department                    = ControlOperations.Department
	|	AND Operations.Stage                             = ControlOperations.Stage
	|	
	|	LEFT JOIN Balance AS LaborCostsToRegister
	|	ON Operations.Ref = LaborCostsToRegister.ReferenceOrder
	|	
	|	LEFT JOIN TTOperationCalculationArticles AS ArticlesOfCalculationOfOperations
	|	ON Operations.Ref = ArticlesOfCalculationOfOperations.ProductionOperation
	|	AND LaborCostsToRegister.WorkKind = ArticlesOfCalculationOfOperations.WorkKind
	|
	|	LEFT JOIN TTCalculationArticlesOnNSI AS NSICalculationArticles
	|	ON Operations.OwnerOfTechnologicalOperation = NSICalculationArticles.OwnerOfTechnologicalOperation
	|	AND LaborCostsToRegister.WorkKind = NSICalculationArticles.WorkKind
	|
	|WHERE
	|	ISNULL(ControlOperations.Completed2 + ControlOperations.DefectiveGoods, Operations.CountReal + Operations.DefectiveGoodsCount) > 0
	|
	|;
	|
	|SELECT
	|	Rates.WorkKind AS WorkKind,
	|	Rates.LaborGrade AS LaborGrade,
	|	Rates.Rate_ AS Rate_
	|INTO TTRates
	|FROM
	|	InformationRegister.EmployeeActivityRates.SliceLast(&EndOfPeriod, WorkKind IN (SELECT DD.WorkKind FROM TTLaborCostsForRegistration AS DD)) AS Rates
	|INDEX BY
	|	WorkKind
	|
	|";
	QueriesTexts.Add(QueryText);
	
	SetPrivilegedMode(True);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query.Execute();
	SetPrivilegedMode(False);
	
	#EndRegion
	
	#Region LaborCostsToRegister
	
	Query.Text =
	"SELECT
	|	Filter.Department AS Department,
	|	Filter.Team AS Team,
	|	Filter.WorkOrderKind AS WorkOrderKind
	|INTO WSelectionByStructure
	|FROM
	|	&StructuralSelection AS Filter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.WorkOrderKind AS WorkOrderKind,
	|	DD.ExecutionDate AS ExecutionDate,
	|	DD.Periodicity AS Periodicity,
	|	CASE
	|		WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.DAY)
	|			THEN BEGINOFPERIOD(DD.ExecutionDate, DAY)
	|		ELSE
	|			BEGINOFPERIOD(DD.ExecutionDate, MONTH)
	|	END AS Period,
	|	CASE
	|		WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.DAY)
	|			THEN BEGINOFPERIOD(DD.ExecutionDate, DAY)
	|		WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.MONTH)
	|			THEN BEGINOFPERIOD(DD.ExecutionDate, MONTH)
	|		ELSE
	|			DD.ExecutionDate
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.DAY)
	|			THEN ENDOFPERIOD(DD.ExecutionDate, DAY)
	|		WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.MONTH)
	|			THEN ENDOFPERIOD(DD.ExecutionDate, MONTH)
	|		ELSE
	|			DD.ExecutionDate
	|	END AS EndOfPeriod,
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	DD.WorkKind AS WorkKind,
	|	DD.QuantityToRegister,
	|	DD.AmountDueForPayment,
	|	CASE
	|		WHEN NOT Rates.Rate_ IS NULL
	|			THEN Rates.Rate_ * CASE
	|										WHEN ActivityKinds.RatePerHourWorked
	|											THEN ActivityKinds.LaborInput / ActivityKinds.LaborInputMultiplier
	|										ELSE 1
	|									END
	|		ELSE 0
	|	END AS Rate_,
	|	DD.AmountDueForPayment * CASE
	|		WHEN NOT Rates.Rate_ IS NULL
	|			THEN Rates.Rate_ * CASE
	|										WHEN ActivityKinds.RatePerHourWorked
	|											THEN ActivityKinds.LaborInput / ActivityKinds.LaborInputMultiplier
	|										ELSE 1
	|									END
	|		ELSE 0
	|	END AS Sum,
	|	DD.Organization AS Organization,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.Performer AS Performer,
	|	CASE
	|		WHEN DD.Performer REFS Catalog.Teams
	|			THEN DD.Performer
	|	END AS Team,
	|	CASE
	|		WHEN DD.Performer REFS Catalog.Persons
	|			THEN DD.Performer
	|		WHEN DD.Performer REFS Catalog.EmployeesHR
	|			THEN EmployeesHR.Individual
	|	END AS Employee_,
	|	CASE
	|		WHEN DD.Performer REFS Catalog.EmployeesHR
	|			THEN DD.Performer
	|	END AS Employee,
	|	DD.Department AS Department,
	|	DD.ProductsGroup AS ProductsGroup,
	|	DD.ProductCostElement AS ProductCostElement
	|INTO LaborCostsToRegister
	|FROM
	|	TTLaborCostsForRegistration AS DD
	|	LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
	|	ON DD.Performer REFS Catalog.EmployeesHR
	|	AND DD.Performer = EmployeesHR.Ref
	|	LEFT JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|	ON DD.WorkKind = ActivityKinds.Ref
	|	LEFT JOIN TTRates AS Rates
	|	ON DD.WorkKind = Rates.WorkKind
	|	AND NOT ActivityKinds.RateAccordingToPayScale
	|	AND ((NOT &UseLaborGradesOfEmployeeActivityRates OR ActivityKinds.LaborGrade = Rates.LaborGrade)
	|	)
	|
	|WHERE
	|	(&NoSelectionByPeriod OR
	|		CASE
	|			WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.DAY)
	|				THEN BEGINOFPERIOD(DD.ExecutionDate, DAY) IN (&TimeIntervals)
	|			WHEN DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.MONTH)
	|				THEN BEGINOFPERIOD(DD.ExecutionDate, MONTH) IN (&TimeIntervals)
	|			ELSE
	|				TRUE
	|		END)
	|	AND (&BeginOfPeriod = DATETIME(1,1,1) OR BEGINOFPERIOD(DD.ExecutionDate, DAY) >= &BeginOfPeriod)
	|	AND (&EndOfPeriod = DATETIME(1,1,1) OR BEGINOFPERIOD(DD.ExecutionDate, DAY) <= &EndOfPeriod)
	|	AND (&NoSelectionByOutfitType OR DD.WorkOrderKind IN (&WorkOrderKinds))
	|	AND (&WithoutSelectionByTypeOfOutfitsAndDivisions OR (DD.Department, DD.WorkOrderKind,
	|		CASE
	|			WHEN VALUETYPE(DD.Performer) = TYPE(Catalog.Teams)
	|				THEN DD.Performer
	|			ELSE VALUE(Catalog.Teams.EmptyRef)
	|		END) IN (
	|		SELECT
	|			Filter.Department AS Department,
	|			Filter.WorkOrderKind AS WorkOrderKind,
	|			Filter.Team AS Team
	|		FROM WSelectionByStructure AS Filter))
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.WorkOrderKind AS WorkOrderKind,
	|	DD.Period AS Period,
	|	MIN(BEGINOFPERIOD(DD.BeginOfPeriod, DAY)) AS BeginOfPeriod,
	|	MAX(ENDOFPERIOD(DD.EndOfPeriod, DAY)) AS EndOfPeriod,
	|	DD.Organization AS Organization,
	|	CASE
	|		WHEN VALUETYPE(DD.Performer) = TYPE(Catalog.Teams)
	|			THEN DD.Performer
	|		ELSE UNDEFINED
	|	END AS Performer,
	|	DD.Department AS Department
	|INTO PreparationForRegistration
	|FROM
	|	LaborCostsToRegister AS DD
	|	
	|WHERE
	|	&CollapseOrders OR DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.Custom)
	|
	|GROUP BY
	|	DD.WorkOrderKind,
	|	DD.Period,
	|	DD.Department,
	|	CASE
	|		WHEN VALUETYPE(DD.Performer) = TYPE(Catalog.Teams)
	|			THEN DD.Performer
	|		ELSE UNDEFINED
	|	END,
	|	DD.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.WorkOrderKind AS WorkOrderKind,
	|	DD.Period AS Period,
	|	MIN(BEGINOFPERIOD(DD.BeginOfPeriod, DAY)) AS BeginOfPeriod,
	|	MAX(ENDOFPERIOD(DD.EndOfPeriod, DAY)) AS EndOfPeriod,
	|	DD.Organization AS Organization,
	|	DD.Performer AS Performer,
	|	DD.Department AS Department
	|FROM
	|	LaborCostsToRegister AS DD
	|	
	|WHERE
	|	NOT &CollapseOrders AND DD.Periodicity <> VALUE(Enum.FrequencyOfWorkOutputRegistration.Custom)
	|
	|GROUP BY
	|	DD.WorkOrderKind,
	|	DD.Period,
	|	DD.Department,
	|	DD.Performer,
	|	DD.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.WorkOrderKind AS WorkOrderKind,
	|	DATETIME(1,1,1) AS ExecutionDate,
	|	DD.Period AS Period,
	|	PreparationForRegistration.BeginOfPeriod AS BeginOfPeriod,
	|	PreparationForRegistration.EndOfPeriod AS EndOfPeriod,
	|	0 AS ReferenceRowCode,
	|	VALUE(Catalog.EmployeeWorkKinds.EmptyRef) AS WorkKind,
	|	SUM(DD.QuantityToRegister) AS QuantityToRegister,
	|	SUM(DD.AmountDueForPayment) AS AmountDueForPayment,
	|	0 AS Rate_,
	|	SUM(DD.Sum) AS Sum,
	|	DD.Organization AS Organization,
	|	UNDEFINED AS ReferenceOrder,
	|	UNDEFINED AS Performer,
	|	DD.Team AS Team,
	|	UNDEFINED AS Employee_,
	|	UNDEFINED AS Employee,
	|	DD.Department AS Department,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	UNDEFINED AS ProductCostElement
	|INTO TTTypesOfWork
	|FROM
	|	LaborCostsToRegister AS DD
	|	LEFT JOIN PreparationForRegistration AS PreparationForRegistration
	|		ON DD.WorkOrderKind = PreparationForRegistration.WorkOrderKind
	|		AND DD.Period = PreparationForRegistration.Period
	|		AND DD.Department = PreparationForRegistration.Department
	|		AND DD.Organization = PreparationForRegistration.Organization
	|		AND (DD.Performer = PreparationForRegistration.Performer OR PreparationForRegistration.Performer = UNDEFINED)
	|		
	|WHERE
	|	&CollapseOrders
	|	
	|GROUP BY
	|	DD.WorkOrderKind,
	|	DD.Period,
	|	DD.Department,
	|	DD.Organization,
	|	PreparationForRegistration.BeginOfPeriod,
	|	PreparationForRegistration.EndOfPeriod,
	|	DD.Team
	|
	|UNION ALL
	|
	|SELECT
	|	DD.WorkOrderKind,
	|	DD.ExecutionDate AS ExecutionDate,
	|	DD.Period AS Period,
	|	PreparationForRegistration.BeginOfPeriod AS BeginOfPeriod,
	|	PreparationForRegistration.EndOfPeriod AS EndOfPeriod,
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	DD.WorkKind AS WorkKind,
	|	SUM(DD.QuantityToRegister) AS QuantityToRegister,
	|	SUM(DD.AmountDueForPayment) AS AmountDueForPayment,
	|	MAX(DD.Rate_) AS Rate_,
	|	SUM(DD.Sum) AS Sum,
	|	DD.Organization AS Organization,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.Performer AS Performer,
	|	DD.Team AS Team,
	|	DD.Employee_ AS Employee_,
	|	DD.Employee AS Employee,
	|	DD.Department AS Department,
	|	DD.ProductsGroup AS ProductsGroup,
	|	DD.ProductCostElement AS ProductCostElement
	|FROM
	|	LaborCostsToRegister AS DD
	|	LEFT JOIN PreparationForRegistration AS PreparationForRegistration
	|		ON DD.WorkOrderKind = PreparationForRegistration.WorkOrderKind
	|		AND DD.Period = PreparationForRegistration.Period
	|		AND DD.Department = PreparationForRegistration.Department
	|		AND DD.Organization = PreparationForRegistration.Organization
	|		AND (DD.Performer = PreparationForRegistration.Performer OR
	|		PreparationForRegistration.Performer = UNDEFINED AND DD.Periodicity = VALUE(Enum.FrequencyOfWorkOutputRegistration.Custom))
	|		
	|WHERE
	|	NOT &CollapseOrders
	|	
	|GROUP BY
	|	DD.WorkOrderKind,
	|	DD.ExecutionDate,
	|	DD.Period,
	|	PreparationForRegistration.BeginOfPeriod,
	|	PreparationForRegistration.EndOfPeriod,
	|	DD.ReferenceRowCode,
	|	DD.WorkKind,
	|	DD.Organization,
	|	DD.ReferenceOrder,
	|	DD.Performer,
	|	DD.Team,
	|	DD.Employee_,
	|	DD.Employee,
	|	DD.ProductsGroup,
	|	DD.Department,
	|	DD.ProductCostElement
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DD.WorkOrderKind AS WorkOrderKind,
	|	DD.Organization AS Organization,
	|	DD.BeginOfPeriod AS BeginOfPeriod,
	|	DD.EndOfPeriod AS EndOfPeriod,
	|	DD.Team AS Team,
	|	DD.Department AS Department,
	|	DD.Department.UseLPR AS UseLPR,
	|	DD.Department.UseTariffRates AS UseTariffRates,
	|	DD.Department.UseHoursWorked AS UseHoursWorked,
	|	DD.ExecutionDate AS ExecutionDate,
	|	BEGINOFPERIOD(CASE
	|		WHEN &IncludeInPeriodOfWork
	|			THEN DD.ExecutionDate
	|		ELSE &CurrentDate
	|	END, DAY) AS WorkExecutionDate,
	|	DD.Period AS Period,
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	DD.WorkKind AS WorkKind,
	|	DD.QuantityToRegister AS QuantityToRegister,
	|	DD.AmountDueForPayment AS AmountDueForPayment,
	|	DD.Rate_ AS Rate_,
	|	DD.Sum AS Sum,
	|	DD.ProductsGroup AS ProductsGroup,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.Performer AS Performer,
	|	DD.Employee_ AS Employee_,
	|	DD.Employee AS Employee,
	|	DD.ProductCostElement AS ProductCostElement
	|INTO ActivityKinds
	|FROM
	|	TTTypesOfWork AS DD
	|";
	
	OrderingText =
	"ORDER BY
	|	DD.WorkOrderKind,
	|	DD.Organization,
	|	DD.BeginOfPeriod,
	|	DD.EndOfPeriod,
	|	DD.Team,
	|	DD.Department,
	|	BEGINOFPERIOD(DD.ExecutionDate, DAY),
	|	DD.Performer,
	|	DD.ReferenceOrder
	|";
	
	#EndRegion
	
	If TempTablesManager <> Undefined Then
		Query.Execute();
		Return True;
	Else
		Query.Text = StrReplace(Query.Text, "INTO ActivityKinds", "");
		Query.Text = Query.Text + OrderingText;
		Return Query.Execute();
	EndIf;
	
EndFunction

// Fills in the list of employees based on previously entered documents.
//
// Parameters:
//  Object			- DocumentObject.WorkOutput, FormDataStructure - The document to fill out.
//  DateOfComposition		- Date - Date of creation of the new team composition.
//
Procedure FillWorkers(Object, Val DateOfComposition = Undefined) Export
	
	Object.Employees.Clear();
	
	If DateOfComposition = Undefined Then
		DateOfComposition = ?(ValueIsFilled(Object.Date), EndOfDay(Object.Date), CurrentSessionDate());
	EndIf;
	
	Brigades = Brigades(DateOfComposition, CommonClientServer.ValueInArray(Object.Team));
	
	FilterStructure1 = New Structure("Team", Object.Team);
	
	If Brigades.FindNext(FilterStructure1) Then
		
		Selection = Brigades.Select();
		
		While Selection.Next() Do
			NewRow = Object.Employees.Add();
			FillPropertyValues(NewRow, Selection);
		EndDo;
		
	EndIf;
	
	If GetFunctionalOption("UsePayroll") Then
		
		FieldsToFillIn_ = BSKIntegration.EmployeePersonnelDataFieldsToFillIn();
		FieldsToFillIn_.TariffRate	= Object.UseTariffRates;
		FieldsToFillIn_.HoursWorked	= Object.UseHoursWorked;
		
		BSKIntegration.FillInPersonnelDataOfEmployees(
			Object,
			"Employees",
			FieldsToFillIn_);
		
	EndIf;
	
	DistributeAmountToParticipants(Object);
	
EndProcedure

// Fills in arrays of details that depend on the document properties
//
// Parameters:
//  Object - DocumentObject.WorkOutput, FormDataStructure - Document
//	ArrayOfAllProps - Array - details that depend on the document properties
//	ArrayOfOperationDetails - Array - details that are used for the specified properties.
//
Procedure NamesOfPropsByTypeOfOutfit(Object, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	MixedArtistType = MixedArtistType(Object);
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Team");
	ArrayOfAllProps.Add("GroupSettingUpMetrics");
	ArrayOfAllProps.Add("GroupPeriodOfExecutionOfWorks");
	ArrayOfAllProps.Add("Allocated");
	ArrayOfAllProps.Add("StartDate");
	ArrayOfAllProps.Add("EndDate");
	ArrayOfAllProps.Add("AutoAllocation");
	
	ArrayOfAllProps.Add("FillInTheTypesOfWork");
	ArrayOfAllProps.Add("ActivityKinds.Employee_");
	ArrayOfAllProps.Add("ActivityKinds.Employee");
	ArrayOfAllProps.Add("ActivityKinds.AssigneeQualification");
	ArrayOfAllProps.Add("ActivityKinds.ProductsGroup");
	ArrayOfAllProps.Add("ActivityKinds.ReferenceOrder");
	ArrayOfAllProps.Add("ActivityKinds.ReferenceRowCode");
	ArrayOfAllProps.Add("ActivityKinds.ProductCostElement");
	
	ArrayOfAllProps.Add("Employees");
	ArrayOfAllProps.Add("Employees.Employee_");
	ArrayOfAllProps.Add("Employees.Employee");
	ArrayOfAllProps.Add("EmployeesFillInThePersonnelData");
	ArrayOfAllProps.Add("EmployeesTariffRate");
	ArrayOfAllProps.Add("EmployeesWorkedOut");
	
	ArrayOfOperationDetails = New Array;
	
	If Object.WorkOrderKind = Enums.TeamWorkOrderKinds.Personal Then
		
		ArrayOfOperationDetails.Add("GroupPeriodOfExecutionOfWorks");
		ArrayOfOperationDetails.Add("StartDate");
		ArrayOfOperationDetails.Add("EndDate");
		
		ArrayOfOperationDetails.Add("FillInTheTypesOfWork");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceOrder");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceRowCode");
		ArrayOfOperationDetails.Add("ActivityKinds.AssigneeQualification");
		ArrayOfOperationDetails.Add("ActivityKinds.ProductCostElement");
		If Object.AccountingForLaborCostsByEmployees Then
			ArrayOfOperationDetails.Add("ActivityKinds.Employee");
			If MixedArtistType Then
				ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
			EndIf;
		Else
			ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
		EndIf;
		
	ElsIf Object.WorkOrderKind = Enums.TeamWorkOrderKinds.TeamKind Then
		
		ArrayOfOperationDetails.Add("Team");
		ArrayOfOperationDetails.Add("GroupSettingUpMetrics");
		ArrayOfOperationDetails.Add("Allocated");
		ArrayOfOperationDetails.Add("GroupPeriodOfExecutionOfWorks");
		ArrayOfOperationDetails.Add("StartDate");
		ArrayOfOperationDetails.Add("EndDate");
		
		ArrayOfOperationDetails.Add("FillInTheTypesOfWork");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceOrder");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceRowCode");
		ArrayOfOperationDetails.Add("ActivityKinds.ProductCostElement");
		
		ArrayOfOperationDetails.Add("Employees");
		ArrayOfOperationDetails.Add("EmployeesFillInThePersonnelData");
		ArrayOfOperationDetails.Add("EmployeesTariffRate");
		ArrayOfOperationDetails.Add("EmployeesWorkedOut");
		
		If Object.AccountingForLaborCostsByEmployees Then
			ArrayOfOperationDetails.Add("Employees.Employee");
		Else
			ArrayOfOperationDetails.Add("Employees.Employee_");
		EndIf;
		
	ElsIf Object.WorkOrderKind = Enums.TeamWorkOrderKinds.TeamByOrder21 Then
		
		ArrayOfOperationDetails.Add("Team");
		ArrayOfOperationDetails.Add("AutoAllocation");
		ArrayOfOperationDetails.Add("GroupPeriodOfExecutionOfWorks");
		ArrayOfOperationDetails.Add("StartDate");
		ArrayOfOperationDetails.Add("EndDate");
		
		ArrayOfOperationDetails.Add("FillInTheTypesOfWork");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceOrder");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceRowCode");
		ArrayOfOperationDetails.Add("ActivityKinds.ProductCostElement");
		
		If Object.AutoAllocation Then
			ArrayOfOperationDetails.Add("Employees");
			ArrayOfOperationDetails.Add("Allocated");
		Else
			ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
		EndIf;
		
	ElsIf Object.WorkOrderKind = Enums.TeamWorkOrderKinds.TeamWithoutOrder21 Then
		
		ArrayOfOperationDetails.Add("Team");
		ArrayOfOperationDetails.Add("AutoAllocation");
		
		ArrayOfOperationDetails.Add("ActivityKinds.ProductsGroup");
		
		If Object.AutoAllocation Then
			ArrayOfOperationDetails.Add("Employees");
			ArrayOfOperationDetails.Add("Allocated");
		Else
			ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
		EndIf;
		
	ElsIf Object.WorkOrderKind = Enums.TeamWorkOrderKinds.OtherActivities Then
		
		ArrayOfOperationDetails.Add("Team");
		ArrayOfOperationDetails.Add("AutoAllocation");
		If Object.AutoAllocation Then
			ArrayOfOperationDetails.Add("Employees");
			ArrayOfOperationDetails.Add("Allocated");
			ArrayOfOperationDetails.Add("EmployeesFillInThePersonnelData");
			ArrayOfOperationDetails.Add("EmployeesTariffRate");
			ArrayOfOperationDetails.Add("EmployeesWorkedOut");
			
			If Object.AccountingForLaborCostsByEmployees Then
				ArrayOfOperationDetails.Add("Employees.Employee");
			Else
				ArrayOfOperationDetails.Add("Employees.Employee_");
			EndIf;
		Else
			If Object.AccountingForLaborCostsByEmployees Then
				ArrayOfOperationDetails.Add("ActivityKinds.Employee");
				If MixedArtistType Then
					ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
				EndIf;
			Else
				ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
			EndIf;
		EndIf;
		
	ElsIf Object.WorkOrderKind = Enums.TeamWorkOrderKinds.Repair Then
		
		ArrayOfOperationDetails.Add("Team");
		ArrayOfOperationDetails.Add("AutoAllocation");
		ArrayOfOperationDetails.Add("GroupPeriodOfExecutionOfWorks");
		ArrayOfOperationDetails.Add("StartDate");
		ArrayOfOperationDetails.Add("EndDate");
		
		ArrayOfOperationDetails.Add("FillInTheTypesOfWork");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceOrder");
		ArrayOfOperationDetails.Add("ActivityKinds.ReferenceRowCode");
		If Object.AutoAllocation Then
			ArrayOfOperationDetails.Add("Employees");
			ArrayOfOperationDetails.Add("Allocated");
			ArrayOfOperationDetails.Add("EmployeesFillInThePersonnelData");
			ArrayOfOperationDetails.Add("EmployeesTariffRate");
			ArrayOfOperationDetails.Add("EmployeesWorkedOut");
			
			If Object.AccountingForLaborCostsByEmployees Then
				ArrayOfOperationDetails.Add("Employees.Employee");
			Else
				ArrayOfOperationDetails.Add("Employees.Employee_");
			EndIf;
		Else
			If Object.AccountingForLaborCostsByEmployees Then
				ArrayOfOperationDetails.Add("ActivityKinds.Employee");
				If MixedArtistType Then
					ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
				EndIf;
			Else
				ArrayOfOperationDetails.Add("ActivityKinds.Employee_");
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Distributes the number and amount of types of work by performers.
//
// Parameters:
//	Object - DocumentObject.WorkOutput - the document where the distribution is performed.
//
Procedure DistributeAmountToParticipants(Object) Export
	
	If Not Object.UseLPR
		And Not Object.UseTariffRates
		And Not Object.UseHoursWorked Then
		Return;
	EndIf;
	
	Result = DistributionOfTypesOfWorkByEmployees(Object, False, False, False);
	Result.GroupBy("IndexOf", "StandardCost");
	
	For Each CurrentData In Result Do
		Object.Employees[CurrentData.IndexOf].Sum = CurrentData.StandardCost;
	EndDo;
	
EndProcedure

#Region DownloadingFromVHFFile

// Sets the download parameters.
//
// Parameters:
//   Parameters - Structure - download parameters from a file.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	ColumnDataType = Parameters.ColumnDataType;
	
	ColumnDataType.Insert("EmployeeCode",    New TypeDescription("String",, New StringQualifiers(11)));
	ColumnDataType.Insert("Employee_",        New TypeDescription("String",, New StringQualifiers(150)));
	ColumnDataType.Insert("LPR",             New TypeDescription("Number",,  New NumberQualifiers(15, 2)));
	ColumnDataType.Insert("TariffRate",  New TypeDescription("Number",,  New NumberQualifiers(15, 2)));
	ColumnDataType.Insert("HoursWorked", New TypeDescription("Number",,  New NumberQualifiers(15, 3)));
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Employees  = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData);
	
	QueryText = "
	|SELECT
	|	DataToImport.EmployeeCode  AS EmployeeCode,
	|	DataToImport.Employee_      AS Employee_,
	|	&LPR,
	|	&TariffRate,
	|	&HoursWorked,
	|	DataToImport.Id AS Id
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Individuals.Id                   AS Id,
	|	MAX(Individuals.Employees)             AS Employees,
	|	COUNT(DISTINCT Individuals.Employees) AS NumberOfEmployees_
	|INTO TTEmployeeData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Individuals.Ref                  AS Employees
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Persons AS Individuals
	|		ON Individuals.Code = DataToImport.EmployeeCode
	|
	|	WHERE
	|		NOT DataToImport.EmployeeCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Individuals.Ref                  AS Employees
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Persons AS Individuals
	|		ON Individuals.Description = DataToImport.Employee_
	|
	|	WHERE
	|		NOT DataToImport.Employee_ = """"
	|	) AS Individuals
	|
	|GROUP BY
	|	Individuals.Id
	|
	|INDEX BY
	|	Id,
	|	Employees
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	CASE
	|		WHEN ISNULL(EmployeeData.NumberOfEmployees_, 0) = 1
	|			THEN EmployeeData.Employees
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|	END                                                    AS Employee_,
	|	ISNULL(EmployeeData.NumberOfEmployees_, 0)       AS NumberOfEmployees_,
	|	&LPR,
	|	&TariffRate,
	|	&HoursWorked,
	|	DataToImport.Id                          AS Id
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTEmployeeData AS EmployeeData
	|	ON EmployeeData.Id = DataToImport.Id";
	
	QueryText = StrReplace(QueryText, "&LPR,",
		?(AdditionalParameters.UseLPR, "DataToImport.LPR AS LPR,", ""));
	
	QueryText = StrReplace(QueryText, "&TariffRate,",
		?(AdditionalParameters.UseTariffRates, "DataToImport.TariffRate AS TariffRate,", ""));
	
	QueryText = StrReplace(QueryText, "&HoursWorked,",
		?(AdditionalParameters.UseHoursWorked, "DataToImport.HoursWorked AS HoursWorked,", ""));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport", DataToImport);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Employees.Add();
		FillPropertyValues(NewRow, Selection);
		
		If AdditionalParameters.UseLPR And NewRow.LPR = 0 Then
			NewRow.LPR = 1;
		EndIf;
		
		If Selection.NumberOfEmployees_ > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Employee_";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Employees, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
// 	FullTabularSectionName- String - full name of the table part where data is loaded.
// 	ConflictsList - Array - list of ambiguities.
// 	ColumnName - String - name of the column where the ambiguity occurs.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	Query = New Query;
	
	If ColumnName = "Employee_" Then
		
		Query.Text =
		"SELECT
		|	Individuals.Ref AS Ref
		|FROM
		|	(SELECT
		|		Individuals.Ref AS Ref
		|	FROM
		|		Catalog.Persons AS Individuals
		|
		|	WHERE
		|		NOT &EmployeeCode = """"
		|		AND Individuals.Code = &EmployeeCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		Individuals.Ref AS Ref
		|	FROM
		|		Catalog.Persons AS Individuals
		|
		|	WHERE
		|		NOT &Employee_ = """"
		|		AND Individuals.Description = &Employee_
		|	) AS Individuals
		|
		|GROUP BY
		|	Individuals.Ref
		|";
		
		Query.SetParameter("EmployeeCode", LoadedValuesString.EmployeeCode);
		Query.SetParameter("Employee_",     LoadedValuesString.Employee_);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		If AccessRight("Insert", Metadata.Documents.WorkOutput)
			And (GetFunctionalOption("EnterpriseManagement")
				Or GetFunctionalOption("UseProductionManagement2_2")) Then
			SelectedForm = "DocumentsListForm";
		Else
			SelectedForm = "ListForm";
		EndIf; 
	EndIf; 
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments) Export
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.PieceworkRegistration;
	String.FullDocumentName           = Metadata.Documents.WorkOutput.FullName();
	String.PurposeUseKey  = "WorkOutput";
	String.WorkplaceTitle       = NStr("vi = 'Sản lượng của nhân viên';
										|ru = 'Выработка сотрудников';
										|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
										|it = 'Produttività dei dipendenti';
										|pl = 'Ustawienia wydajności pracowników';
										|tr = 'Zaman çizelgesi bazlı ücretlendirme'");
	String.AccessRightInsert       = True;
	String.Order                      = 1;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
							BusinessTransactionsAndDocuments, 
							New ValueList, 
							New ValueList, 
							"");
	
	Return TableOfValuesAvailable;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.Ref            AS Ref,
	|	Attributes.Date              AS Date,
	|	Attributes.Number             AS Number,
	|	ENDOFPERIOD(Attributes.Date, DAY) AS Period,
	|	Attributes.Month             AS Month,
	|	Attributes.Team           AS Team,
	|	Attributes.Organization       AS Organization,
	|	Attributes.Department     AS Department,
	|	Attributes.DocumentAmount    AS DocumentAmount,
	|	Attributes.Currency            AS Currency,
	|	Attributes.WorkOrderKind         AS WorkOrderKind,
	|	Attributes.AutoAllocation AS AutoAllocation,
	|	Attributes.Patch		AS Patch
	|FROM
	|	Document.WorkOutput AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Attributes.Currency, Attributes.Currency, Attributes.Date, Attributes.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
	
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(Type("DocumentRef.WorkOutput")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	ObsoleteSpecies = New Array;
	ObsoleteSpecies.Add(Enums.TeamWorkOrderKinds.Repair);
	ObsoleteSpecies.Add(Enums.TeamWorkOrderKinds.OtherActivities);
	ObsoleteSpecies.Add(Enums.TeamWorkOrderKinds.TeamByOrder21);
	ObsoleteSpecies.Add(Enums.TeamWorkOrderKinds.TeamWithoutOrder21);
	Query.SetParameter("ObsoleteSpecies", ObsoleteSpecies);
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	DataSources.Insert("ActivityKinds.ReferenceOrder");
	
	Return DataSources; 
	
EndFunction

Procedure SetQueryParameterTableTypesOfEmployees(Query, RegisterName, DetailedRecords)
	
	If Query.Parameters.Property(RegisterName) Then
		Return;
	EndIf;
	
	OutdatedOnArticles = New Array;
	OutdatedOnArticles.Add(Enums.TeamWorkOrderKinds.Repair);
	OutdatedOnArticles.Add(Enums.TeamWorkOrderKinds.OtherActivities);
	
	ObsoleteForProduction = New Array;
	ObsoleteForProduction.Add(Enums.TeamWorkOrderKinds.TeamByOrder21);
	ObsoleteForProduction.Add(Enums.TeamWorkOrderKinds.TeamWithoutOrder21);
	
	If Query.Parameters.WorkOrderKind = Enums.TeamWorkOrderKinds.Personal
		Or OutdatedOnArticles.Find(Query.Parameters.WorkOrderKind) <> Undefined 
		Or Not Query.Parameters.AutoAllocation And ObsoleteForProduction.Find(Query.Parameters.WorkOrderKind) <> Undefined Then
		Query.SetParameter(RegisterName, NewTableOfEmployeeJobs(DetailedRecords));
		Return;
	EndIf;
	
	Query.SetParameter(RegisterName, DistributionOfTypesOfWorkByEmployees(Query.Parameters.Ref, DetailedRecords));
	
EndProcedure

Function NewTableOfEmployeeJobs(DetailedRecords)
	
	Fields = New Array;
	Fields.Add("0 AS IndexOf");
	Fields.Add("LaborCostsOfUnfinishedProduction.Employee AS Employee_");
	Fields.Add("VALUE(Catalog.EmployeesHR.EmptyRef) AS Employee");
	Fields.Add("LaborCostsOfUnfinishedProduction.Count");
	Fields.Add("LaborCostsOfUnfinishedProduction.StandardCost");
	Fields.Add("DATETIME(1,1,1) AS WorkExecutionDate");
	If DetailedRecords Then
		Fields.Add("LaborCostsOfUnfinishedProduction.ProductionLot");
		Fields.Add("LaborCostsOfUnfinishedProduction.ProductionOrder");
		Fields.Add("LaborCostsOfUnfinishedProduction.RowCodeProducts");
		Fields.Add("LaborCostsOfUnfinishedProduction.Stage");
		Fields.Add("LaborCostsOfUnfinishedProduction.ProductCostElement");
		Fields.Add("LaborCostsOfUnfinishedProduction.WorkKind");
		Fields.Add("LaborCostsOfUnfinishedProduction.ProductsGroup");
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 0
	|	&Fields
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS LaborCostsOfUnfinishedProduction
	|";
	Query.Text = StrReplace(Query.Text, "&Fields", StrConcat(Fields, "," + Chars.LF));
	
	Return Query.Execute().Unload();
	
EndFunction

// Distribution of types of work by employees.
// 
// Parameters:
//  Object - DocumentObject.WorkOutput, DocumentRef.WorkOutput, Array of DocumentRef.WorkOutput - object, link, array of links.
//  DetailedRecords - Boolean - Indicates whether the distribution data is detailed.
//  DistributeQuantity - Boolean - Distribute the quantity.
//  DistributeAmount - Boolean - Distribute the amount.
// 
// Returns:
//  ValueTable - Distribution of types of work by employees
Function DistributionOfTypesOfWorkByEmployees(Object, DetailedRecords, GroupingByCompletionDate = True, DistributeQuantity = True, DistributeAmount = True)
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	QueryTexts = New Array;
	
	Fields = New Array;
	Fields.Add("AmountDueForPayment AS Count");
	Fields.Add("Sum AS Sum");
	Fields.Add("DocumentTable.WorkExecutionDate AS WorkExecutionDate");
	If DetailedRecords Then
		Fields.Add("DocumentTable.ReferenceOrder AS ReferenceOrder");
		Fields.Add("DocumentTable.ReferenceRowCode AS ReferenceRowCode");
		Fields.Add("DocumentTable.WorkKind AS WorkKind");
		Fields.Add("DocumentTable.ProductCostElement AS ProductCostElement");
		Fields.Add("DocumentTable.ProductsGroup AS ProductsGroup");
	EndIf;
	
	QueryText =
	"SELECT
	|	&Fields
	|INTO TTTypesOfWork
	|FROM
	|	&ActivityKinds AS DocumentTable
	|WHERE
	|	&LinkCondition_
	|";
	
	QueryText = StrReplace(QueryText, "&Fields", StrConcat(Fields, "," + Chars.LF));
	
	If DetailedRecords Then
		QueryText = QueryText +
		"INDEX BY
		|	ReferenceOrder,
		|	ReferenceRowCode
		|";
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	QueryTexts.Add(
	"SELECT
	|	DocumentTable.LineNumber - 1 AS IndexOf,
	|	DocumentTable.Employee_        AS Employee_,
	|	DocumentTable.Employee       AS Employee,
	|	CASE
	|		WHEN &UseLPR
	|			THEN DocumentTable.LPR
	|		ELSE 1
	|	END *
	|	CASE
	|		WHEN &UseTariffRates
	|			THEN DocumentTable.TariffRate
	|		ELSE 1
	|	END *
	|	CASE
	|		WHEN &UseHoursWorked
	|			THEN DocumentTable.HoursWorked
	|		ELSE 1
	|	END *
	|	CASE
	|		WHEN NOT &UseLPR
	|			AND NOT &UseTariffRates
	|			AND NOT &UseHoursWorked
	|			THEN DocumentTable.Sum
	|		ELSE 1
	|	END                            AS ZoomRatio
	|INTO WWorkers
	|FROM
	|	&Employees AS DocumentTable
	|WHERE
	|	&LinkCondition_
	|");
	
	If DetailedRecords Then
		
		QueryTexts.Add(
		"SELECT
		|	ActivityKinds.ReferenceOrder                              AS ReferenceOrder,
		|	ActivityKinds.ReferenceRowCode                     AS ReferenceRowCode,
		|	CASE
		|		WHEN LaborCostsOfProductionWithoutOrder.Ref.Patch
		|			AND LaborCostsOfProductionWithoutOrder.Ref.CorrectionSavesProductionLots
		|			THEN LaborCostsOfProductionWithoutOrder.Ref.CorrectedDocument
		|		ELSE LaborCostsOfProductionWithoutOrder.Ref
		|	END                                               AS DocumentLots,
		|	LaborCostsOfProductionWithoutOrder.CostGroupNumber AS CostGroupNumber
		|INTO TTDocumentsOfProductionBatchesWithoutOrder
		|FROM
		|	TTTypesOfWork AS ActivityKinds
		|
		|	INNER JOIN Document.BackflushProduction.LaborCosts AS LaborCostsOfProductionWithoutOrder
		|	ON LaborCostsOfProductionWithoutOrder.Ref = ActivityKinds.ReferenceOrder
		|	AND LaborCostsOfProductionWithoutOrder.RowCode = ActivityKinds.ReferenceRowCode
		|
		|GROUP BY
		|	ActivityKinds.ReferenceOrder,
		|	ActivityKinds.ReferenceRowCode,
		|	LaborCostsOfProductionWithoutOrder.Ref,
		|	LaborCostsOfProductionWithoutOrder.CostGroupNumber
		|
		|INDEX BY
		|	ReferenceOrder,
		|	ReferenceRowCode
		|");
		
		QueryTexts.Add(
		"SELECT
		|	ActivityKinds.ReferenceOrder          AS ReferenceOrder,
		|	&ExecutionDate                 AS WorkExecutionDate,
		|	ActivityKinds.ReferenceRowCode AS ReferenceRowCode,
		|	CatProductionLots.Ref    AS ProductionLot
		|INTO TTBatchProductionWithoutOrder
		|FROM
		|	TTTypesOfWork AS ActivityKinds
		|
		|	INNER JOIN TTDocumentsOfProductionBatchesWithoutOrder AS TTDocumentsOfProductionBatchesWithoutOrder
		|	ON TTDocumentsOfProductionBatchesWithoutOrder.ReferenceOrder = ActivityKinds.ReferenceOrder
		|	AND TTDocumentsOfProductionBatchesWithoutOrder.ReferenceRowCode = ActivityKinds.ReferenceRowCode
		|
		|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
		|	ON CatProductionLots.Document = TTDocumentsOfProductionBatchesWithoutOrder.DocumentLots
		|	AND CatProductionLots.Code = TTDocumentsOfProductionBatchesWithoutOrder.CostGroupNumber
		|	AND NOT CatProductionLots.DeletionMark
		|
		|GROUP BY
		|	ActivityKinds.ReferenceOrder,
		|	&ExecutionDate,
		|	ActivityKinds.ReferenceRowCode,
		|	CatProductionLots.Ref
		|
		|INDEX BY
		|	ReferenceOrder,
		|	ReferenceRowCode
		|");
		
		QueryTexts.Add(
		"SELECT
		|	ActivityKinds.WorkKind                      AS WorkKind,
		|	&ExecutionDate                         AS WorkExecutionDate,
		|	ActivityKinds.ProductCostElement             AS ProductCostElement,
		|	SUM(ActivityKinds.Count)             AS Count,
		|	SUM(ActivityKinds.Sum)                  AS Sum,
		|	CASE
		|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.BackflushProduction)
		|			THEN BatchProductionWithoutOrder.ProductionLot
		|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
		|			THEN CAST(ActivityKinds.ReferenceOrder AS Document.ProductionStage2_2).ProductionLot
		|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.ProductionOperation2_2)
		|			THEN CAST(ActivityKinds.ReferenceOrder AS Document.ProductionOperation2_2).Stage.ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END                                   AS ProductionLot,
		|	ActivityKinds.ProductsGroup               AS ProductsGroup
		|FROM
		|	TTTypesOfWork AS ActivityKinds
		|
		|	LEFT JOIN TTBatchProductionWithoutOrder AS BatchProductionWithoutOrder
		|	ON BatchProductionWithoutOrder.ReferenceOrder = ActivityKinds.ReferenceOrder
		|	AND BatchProductionWithoutOrder.ReferenceRowCode = ActivityKinds.ReferenceRowCode
		|
		|GROUP BY
		|	ActivityKinds.ProductCostElement,
		|	ActivityKinds.WorkKind,
		|	&ExecutionDate,
		|	CASE
		|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.BackflushProduction)
		|			THEN BatchProductionWithoutOrder.ProductionLot
		|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
		|			THEN CAST(ActivityKinds.ReferenceOrder AS Document.ProductionStage2_2).ProductionLot
		|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.ProductionOperation2_2)
		|			THEN CAST(ActivityKinds.ReferenceOrder AS Document.ProductionOperation2_2).Stage.ProductionLot
		|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
		|	END,
		|	ActivityKinds.ProductsGroup
		|");
	Else
		QueryTexts.Add(
		"SELECT
		|	&ExecutionDate             AS WorkExecutionDate,
		|	SUM(ActivityKinds.Count) AS Count,
		|	SUM(ActivityKinds.Sum)      AS Sum
		|FROM
		|	TTTypesOfWork AS ActivityKinds
		|
		|GROUP BY
		|	&ExecutionDate
		|");
	EndIf;
	
	QueryTexts.Add(
	"SELECT
	|	WWorkers.IndexOf      AS IndexOf,
	|	WWorkers.Employee_    AS Employee_,
	|	WWorkers.Employee   AS Employee,
	|	WWorkers.ZoomRatio AS ZoomRatio
	|FROM
	|	WWorkers AS WWorkers
	|
	|ORDER BY
	|	ZoomRatio
	|");
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	LinkCondition_ = "TRUE";
	If TypeOf(Object) = Type("DocumentRef.WorkOutput")
		Or TypeOf(Object) = Type("Array") Then
		
		Query.Text = StrReplace(Query.Text, "&ActivityKinds", "Document.WorkOutput.ActivityKinds");
		Query.Text = StrReplace(Query.Text, "&Employees", "Document.WorkOutput.Employees");
		Query.Text = StrReplace(Query.Text, "&UseLPR", "DocumentTable.Ref.UseLPR");
		Query.Text = StrReplace(Query.Text, "&UseTariffRates", "DocumentTable.Ref.UseTariffRates");
		Query.Text = StrReplace(Query.Text, "&UseHoursWorked", "DocumentTable.Ref.UseHoursWorked");
		
		LinkCondition_ = "DocumentTable.Ref IN (&Objects)";
		
		Query.SetParameter("Objects", Object);
		
	Else
		
		Query.SetParameter("ActivityKinds", Object.ActivityKinds.Unload());
		Query.SetParameter("Employees", Object.Employees.Unload());
		Query.SetParameter("UseLPR", Object.UseLPR);
		Query.SetParameter("UseTariffRates", Object.UseTariffRates);
		Query.SetParameter("UseHoursWorked", Object.UseHoursWorked);
		
	EndIf;
	
	If GroupingByCompletionDate Then
		Query.Text = StrReplace(Query.Text, "&ExecutionDate", "ActivityKinds.WorkExecutionDate");
	Else
		Query.SetParameter("ExecutionDate", Date(1, 1, 1));
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&LinkCondition_", LinkCondition_);
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	ActivityKinds = Results[Results.UBound() - 1].Select();
	Employees = Results[Results.UBound()].Unload();
	
	Coefficients = Employees.UnloadColumn("ZoomRatio");
	Result = NewTableOfEmployeeJobs(DetailedRecords);
	
	While ActivityKinds.Next() Do
		
		If DistributeQuantity Then
			Quantities = Common.DistributeAmountInProportionToCoefficients(ActivityKinds.Count, Coefficients, 3);
		EndIf;
		
		If DistributeAmount Then
			Amounts = Common.DistributeAmountInProportionToCoefficients(ActivityKinds.Sum, Coefficients);
		EndIf;
		
		If DistributeQuantity
				And Not Quantities = Undefined
			Or DistributeAmount
				And Not Amounts = Undefined Then
			
			IndexOf = 0;
			For Each String In Employees Do
				
				NewRow = Result.Add();
				
				FillPropertyValues(NewRow, ActivityKinds);
				
				NewRow.IndexOf    = String.IndexOf;
				NewRow.Employee_  = String.Employee_;
				NewRow.Employee = String.Employee;
				
				If DistributeQuantity Then
					NewRow.Count = Quantities[IndexOf];
				EndIf;
				
				If DistributeAmount Then
					NewRow.StandardCost = Amounts[IndexOf];
				EndIf;
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.WorkOutput";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
		
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, QueryTexts, Undefined);
		SynonymForDocumentTable = "DD";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#Region TemporaryTable

Function RequestTextTTTypesOfEmployeesWork(Query, QueryTexts, RegisterName, DetailedRecords)
	
	SetQueryParameterTableTypesOfEmployees(Query, RegisterName, DetailedRecords);
	
	Fields = New Array;
	Fields.Add("WorkOfEmployees.Employee_");
	Fields.Add("WorkOfEmployees.Employee");
	Fields.Add("WorkOfEmployees.Count");
	Fields.Add("WorkOfEmployees.StandardCost");
	Fields.Add("WorkOfEmployees.WorkExecutionDate");
	If DetailedRecords Then
		Fields.Add("WorkOfEmployees.ProductionLot");
		Fields.Add("WorkOfEmployees.ProductionOrder");
		Fields.Add("WorkOfEmployees.RowCodeProducts");
		Fields.Add("WorkOfEmployees.Stage");
		Fields.Add("WorkOfEmployees.ProductCostElement");
		Fields.Add("WorkOfEmployees.WorkKind");
		Fields.Add("WorkOfEmployees.ProductsGroup");
	EndIf;
	
	QueryText =
	"SELECT
	|	&SelectionFields
	|INTO RegisterName
	|FROM
	|	&RegisterName AS WorkOfEmployees
	|";
	
	QueryText = StrReplace(QueryText, "&SelectionFields", StrConcat(Fields, "," + Chars.LF));
	QueryText = StrReplace(QueryText, "RegisterName", RegisterName);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDocumentsOfProductionBatchesWithoutOrder(Query, QueryTexts)
	
	RegisterName = "TTDocumentsOfProductionBatchesWithoutOrder";
	
	QueryText =
	"SELECT
	|	TableLaborCosts.ReferenceOrder                    AS ReferenceOrder,
	|	TableLaborCosts.ReferenceRowCode           AS ReferenceRowCode,
	|	CASE
	|		WHEN LaborCostsOfProductionWithoutOrder.Ref.Patch
	|			AND LaborCostsOfProductionWithoutOrder.Ref.CorrectionSavesProductionLots
	|			THEN LaborCostsOfProductionWithoutOrder.Ref.CorrectedDocument
	|		ELSE LaborCostsOfProductionWithoutOrder.Ref
	|	END                                               AS DocumentLots,
	|	LaborCostsOfProductionWithoutOrder.CostGroupNumber AS CostGroupNumber
	|INTO TTDocumentsOfProductionBatchesWithoutOrder
	|FROM
	|	Document.WorkOutput.ActivityKinds AS TableLaborCosts
	|	
	|	INNER JOIN Document.BackflushProduction.LaborCosts AS LaborCostsOfProductionWithoutOrder
	|	ON LaborCostsOfProductionWithoutOrder.Ref = TableLaborCosts.ReferenceOrder
	|	AND LaborCostsOfProductionWithoutOrder.RowCode = TableLaborCosts.ReferenceRowCode
	|
	|WHERE
	|	TableLaborCosts.Ref = &Ref
	|
	|GROUP BY
	|	TableLaborCosts.ReferenceOrder,
	|	TableLaborCosts.ReferenceRowCode,
	|	LaborCostsOfProductionWithoutOrder.Ref,
	|	LaborCostsOfProductionWithoutOrder.CostGroupNumber
	|
	|INDEX BY
	|	ReferenceOrder,
	|	ReferenceRowCode
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion


Function QueryTextTableWIPLaborCosts(Query, QueryTexts, Registers)
	
	RegisterName = "WIPLaborCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfEmployeeWork", QueryTexts) Then
		RequestTextTTTypesOfEmployeesWork(Query, QueryTexts, "TTTableTypesOfEmployeeWork", True);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentsOfProductionBatchesWithoutOrder", QueryTexts) Then
		QueryTextTTDocumentsOfProductionBatchesWithoutOrder(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &Patch
	|			THEN BEGINOFPERIOD(&Date, MONTH)
	|		ELSE &Month
	|	END                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	CASE
	|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.BackflushProduction)
	|			AND NOT ActivityKinds.ReferenceOrder = VALUE(Document.BackflushProduction.EmptyRef)
	|			THEN CatBatchProductionProductionWithoutOrder.Ref
	|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(ActivityKinds.ReferenceOrder AS Document.ProductionStage2_2).ProductionLot
	|		WHEN VALUETYPE(ActivityKinds.ReferenceOrder) = TYPE(Document.ProductionOperation2_2)
	|			THEN CAST(ActivityKinds.ReferenceOrder AS Document.ProductionOperation2_2).Stage.ProductionLot
	|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
	|	END                                  AS ProductionLot,
	|	ActivityKinds.ProductCostElement            AS ProductCostElement,
	|	ActivityKinds.WorkKind                     AS WorkKind,
	|	ActivityKinds.ProductsGroup              AS ProductsGroup,
	|	ActivityKinds.Employee_                     AS Employee,
	|	ActivityKinds.AmountDueForPayment            AS Count,
	|	ActivityKinds.Sum * &ConversionRateToManCurrency AS StandardCost,
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|FROM
	|	Document.WorkOutput.ActivityKinds AS ActivityKinds
	|
	|	LEFT JOIN TTDocumentsOfProductionBatchesWithoutOrder AS DocumentsOfProductionBatchesWithoutOrder
	|	ON DocumentsOfProductionBatchesWithoutOrder.ReferenceOrder = ActivityKinds.ReferenceOrder
	|	AND DocumentsOfProductionBatchesWithoutOrder.ReferenceRowCode = ActivityKinds.ReferenceRowCode
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatBatchProductionProductionWithoutOrder
	|	ON CatBatchProductionProductionWithoutOrder.Document = DocumentsOfProductionBatchesWithoutOrder.DocumentLots
	|	AND CatBatchProductionProductionWithoutOrder.Code = DocumentsOfProductionBatchesWithoutOrder.CostGroupNumber
	|	AND NOT CatBatchProductionProductionWithoutOrder.DeletionMark
	|
	|WHERE
	|	ActivityKinds.Ref = &Ref
	|	AND (&WorkOrderKind = VALUE(Enum.TeamWorkOrderKinds.Personal)
	|		OR &WorkOrderKind IN (&ObsoleteSpecies) AND NOT &AutoAllocation)
	|	AND NOT ActivityKinds.AmountDueForPayment = 0
	|	AND NOT ActivityKinds.Sum * &ConversionRateToManCurrency = 0
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN &Patch
	|			THEN BEGINOFPERIOD(&Date, MONTH)
	|		ELSE &Month
	|	END                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	ActivityKinds.ProductionLot           AS ProductionLot,
	|	ActivityKinds.ProductCostElement            AS ProductCostElement,
	|	ActivityKinds.WorkKind                     AS WorkKind,
	|	ActivityKinds.ProductsGroup              AS ProductsGroup,
	|	ActivityKinds.Employee_                     AS Employee,
	|	ActivityKinds.Count                   AS Count,
	|	ActivityKinds.StandardCost * &ConversionRateToManCurrency AS StandardCost,
	|	0                                      AS Cost,
	|	0                                      AS LocalCost,
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfEmployeeWork AS ActivityKinds
	|
	|WHERE
	|	NOT ActivityKinds.Count = 0
	|	AND NOT ActivityKinds.StandardCost * &ConversionRateToManCurrency = 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLaborCostsToRegister(Query, QueryTexts, Registers)
	
	RegisterName = "LaborCostsToRegister";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentsOfProductionBatchesWithoutOrder", QueryTexts) Then
		QueryTextTTDocumentsOfProductionBatchesWithoutOrder(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CASE
	|		WHEN VALUETYPE(TableLaborCosts.ReferenceOrder) = TYPE(Document.BackflushProduction)
	|			THEN CatBatchProductionProductionWithoutOrder.Ref
	|		WHEN VALUETYPE(TableLaborCosts.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(TableLaborCosts.ReferenceOrder AS Document.ProductionStage2_2).ProductionLot
	|		WHEN VALUETYPE(TableLaborCosts.ReferenceOrder) = TYPE(Document.ProductionOperation2_2)
	|			THEN CAST(TableLaborCosts.ReferenceOrder AS Document.ProductionOperation2_2).Stage.ProductionLot
	|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
	|	END AS ProductionLot,
	|	TableLaborCosts.ReferenceOrder AS ReferenceOrder,
	|	TableLaborCosts.WorkKind AS WorkKind,
	|	&Department AS Department,
	|	&Team AS Performer,
	|	TableLaborCosts.QuantityToRegister AS Count,
	|	TableLaborCosts.ReferenceRowCode AS ReferenceRowCode
	|FROM
	|	Document.WorkOutput.ActivityKinds AS TableLaborCosts
	|
	|	LEFT JOIN TTDocumentsOfProductionBatchesWithoutOrder AS DocumentsOfProductionBatchesWithoutOrder
	|	ON DocumentsOfProductionBatchesWithoutOrder.ReferenceOrder = TableLaborCosts.ReferenceOrder
	|	AND DocumentsOfProductionBatchesWithoutOrder.ReferenceRowCode = TableLaborCosts.ReferenceRowCode
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatBatchProductionProductionWithoutOrder
	|	ON CatBatchProductionProductionWithoutOrder.Document = DocumentsOfProductionBatchesWithoutOrder.DocumentLots
	|	AND CatBatchProductionProductionWithoutOrder.Code = DocumentsOfProductionBatchesWithoutOrder.CostGroupNumber
	|	AND NOT CatBatchProductionProductionWithoutOrder.DeletionMark
	|
	|WHERE
	|	TableLaborCosts.Ref = &Ref
	|	AND &WorkOrderKind IN (VALUE(Enum.TeamWorkOrderKinds.TeamKind),
	|					VALUE(Enum.TeamWorkOrderKinds.Repair),
	|					VALUE(Enum.TeamWorkOrderKinds.TeamByOrder21))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CASE
	|		WHEN VALUETYPE(TableLaborCosts.ReferenceOrder) = TYPE(Document.BackflushProduction)
	|			THEN CatBatchProductionProductionWithoutOrder.Ref
	|		WHEN VALUETYPE(TableLaborCosts.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(TableLaborCosts.ReferenceOrder AS Document.ProductionStage2_2).ProductionLot
	|		WHEN VALUETYPE(TableLaborCosts.ReferenceOrder) = TYPE(Document.ProductionOperation2_2)
	|			THEN CAST(TableLaborCosts.ReferenceOrder AS Document.ProductionOperation2_2).Stage.ProductionLot
	|		ELSE VALUE(Catalog.ProductionLots.EmptyRef)
	|	END,
	|	TableLaborCosts.ReferenceOrder AS ReferenceOrder,
	|	TableLaborCosts.WorkKind AS WorkKind,
	|	&Department AS Department,
	|	CASE
	|		WHEN Development_1.AccountingForLaborCostsByEmployees
	|			AND TableLaborCosts.Employee <> VALUE(Catalog.EmployeesHR.EmptyRef)
	|			THEN TableLaborCosts.Employee
	|		WHEN TRUE
	|			THEN TableLaborCosts.Employee_
	|	END AS Performer,
	|	TableLaborCosts.QuantityToRegister AS Count,
	|	TableLaborCosts.ReferenceRowCode AS ReferenceRowCode
	|FROM
	|	Document.WorkOutput.ActivityKinds AS TableLaborCosts
	|
	|	LEFT JOIN TTDocumentsOfProductionBatchesWithoutOrder AS DocumentsOfProductionBatchesWithoutOrder
	|	ON DocumentsOfProductionBatchesWithoutOrder.ReferenceOrder = TableLaborCosts.ReferenceOrder
	|	AND DocumentsOfProductionBatchesWithoutOrder.ReferenceRowCode = TableLaborCosts.ReferenceRowCode
	|
	|	LEFT JOIN Catalog.ProductionLots AS CatBatchProductionProductionWithoutOrder
	|	ON CatBatchProductionProductionWithoutOrder.Document = DocumentsOfProductionBatchesWithoutOrder.DocumentLots
	|	AND CatBatchProductionProductionWithoutOrder.Code = DocumentsOfProductionBatchesWithoutOrder.CostGroupNumber
	|	AND NOT CatBatchProductionProductionWithoutOrder.DeletionMark
	|	
	|	LEFT JOIN Document.WorkOutput AS Development_1
	|	ON Development_1.Ref = TableLaborCosts.Ref
	|
	|WHERE
	|	TableLaborCosts.Ref = &Ref
	|	AND &WorkOrderKind IN (VALUE(Enum.TeamWorkOrderKinds.Personal))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref									AS Ref,
	|	UNDEFINED							AS RecordSeparator,
	|	DD.Date									AS IBDocumentDate,
	|	DD.Number								AS IBDocumentNumber,
	|	&MetadataIdentifier				AS RefType,
	|	DD.Organization							AS Organization,
	|	VALUE(Enum.BusinessTransactions.PieceworkRegistration) AS BusinessOperation,
	|	UNDEFINED							AS LineOfBusiness,
	|	DD.Department						AS Department,
	|	DD.EmployeeResponsible						AS EmployeeResponsible,
	|	CAST(DD.Comment AS STRING(100))AS Comment,
	|	DD.Currency								AS Currency,
	|	DD.DocumentAmount						AS Sum,
	|	DD.Posted								AS Posted,
	|	DD.DeletionMark						AS DeletionMark,
	|	FALSE									AS AdditionalRecord,
	|	""""									AS More,
	|	DD.Date									AS SourceDocumentDate,
	|	&NumberForPrinting							AS SourceDocumentNumber,
	|	UNDEFINED							AS StorageLocation,
	|	DD.Patch							AS ReverseTransactionCorrection,
	|	DD.ReversedDocument					AS ReversedDocument,
	|	DD.CorrectedDocument					AS CorrectedDocument,
	|	DD.Date									AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.WorkOutput AS DD
	|WHERE
	|	DD.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Read", Metadata.Documents.WorkOutput) Then
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "WorkOutput";
		PrintCommand.Presentation = NStr("vi = 'Sản lượng của nhân viên';
										|ru = 'Выработка сотрудников';
										|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
										|it = 'Produttività dei dipendenti';
										|pl = 'Ustawienia wydajności pracowników';
										|tr = 'Zaman çizelgesi bazlı ücretlendirme'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "WorkOutput") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"WorkOutput",
			NStr("vi = 'Sản lượng của nhân viên';
				|ru = 'Выработка сотрудников';
				|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
				|it = 'Produttività dei dipendenti';
				|pl = 'Ustawienia wydajności pracowników';
				|tr = 'Zaman çizelgesi bazlı ücretlendirme'"),
			EmployeeSeal(ObjectsArray, PrintObjects));
	EndIf;
	
EndProcedure

Function EmployeeSeal(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_WorkOutput";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	WorkOutput.Ref AS Ref,
	|	CASE
	|		WHEN WorkOutput.WorkOrderKind IN (VALUE(Enum.TeamWorkOrderKinds.TeamWithoutOrder21),
	|												VALUE(Enum.TeamWorkOrderKinds.OtherActivities))
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByReferences,
	|	WorkOutput.Date AS DocumentDate,
	|	WorkOutput.Number AS DocumentNumber,
	|	WorkOutput.EmployeeResponsible.Individual AS Manager,
	|	WorkOutput.Department AS Department,
	|	WorkOutput.Team AS Team,
	|	WorkOutput.Currency AS Currency,
	|	WorkOutput.Month AS Month,
	|	""Auto"" AS AreaSuffix
	|FROM
	|	Document.WorkOutput AS WorkOutput
	|WHERE
	|	WorkOutput.Ref IN(&ObjectsArray)
	|	AND (WorkOutput.AutoAllocation OR WorkOutput.WorkOrderKind = VALUE(Enum.TeamWorkOrderKinds.TeamKind))
	|
	|UNION ALL
	|
	|SELECT
	|	WorkOutput.Ref AS Ref,
	|	CASE
	|		WHEN WorkOutput.WorkOrderKind IN (VALUE(Enum.TeamWorkOrderKinds.TeamWithoutOrder21),
	|												VALUE(Enum.TeamWorkOrderKinds.OtherActivities))
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByReferences,
	|	WorkOutput.Date AS DocumentDate,
	|	WorkOutput.Number AS DocumentNumber,
	|	WorkOutput.EmployeeResponsible.Individual AS Manager,
	|	WorkOutput.Department AS Department,
	|	WorkOutput.Team AS Team,
	|	WorkOutput.Currency AS Currency,
	|	WorkOutput.Month AS Month,
	|	""NotAuto"" AS AreaSuffix
	|FROM
	|	Document.WorkOutput AS WorkOutput
	|WHERE
	|	WorkOutput.Ref IN(&ObjectsArray)
	|	AND (NOT WorkOutput.AutoAllocation AND WorkOutput.WorkOrderKind IN (
	|											VALUE(Enum.TeamWorkOrderKinds.TeamByOrder21),
	|											VALUE(Enum.TeamWorkOrderKinds.TeamWithoutOrder21),
	|											VALUE(Enum.TeamWorkOrderKinds.OtherActivities),
	|											VALUE(Enum.TeamWorkOrderKinds.Repair))
	|		OR WorkOutput.WorkOrderKind = VALUE(Enum.TeamWorkOrderKinds.Personal))
	|
	|ORDER BY
	|	WorkOutput.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkOutputActivityKinds.Ref AS Ref,
	|	MIN(WorkOutputActivityKinds.LineNumber) AS LineNumber,
	|	WorkOutputActivityKinds.WorkKind AS WorkKind,
	|	WorkOutputActivityKinds.ProductCostElement AS ProductCostElement,
	|	SUM(WorkOutputActivityKinds.AmountDueForPayment) AS AmountDueForPayment,
	|	SUM(WorkOutputActivityKinds.QuantityToRegister) AS QuantityToRegister,
	|	WorkOutputActivityKinds.Rate_ AS Rate_,
	|	SUM(WorkOutputActivityKinds.Sum) AS Sum,
	|	WorkOutputActivityKinds.ReferenceOrder.Number AS OrderNumber__,
	|	WorkOutputActivityKinds.ReferenceOrder.Date AS Order_Date,
	|	WorkOutputActivityKinds.WorkKind.UnitOfMeasure AS UnitOfMeasure,
	|	CASE
	|		WHEN WorkOutputActivityKinds.ReferenceOrder REFS Document.RMOrder
	|			THEN &SynonymForRepairOrder
	|		WHEN TRUE
	|			THEN """"
	|	END AS TypeOfOrder_
	|FROM
	|	Document.WorkOutput.ActivityKinds AS WorkOutputActivityKinds
	|WHERE
	|	WorkOutputActivityKinds.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	WorkOutputActivityKinds.Ref,
	|	WorkOutputActivityKinds.WorkKind,
	|	WorkOutputActivityKinds.ProductCostElement,
	|	WorkOutputActivityKinds.Rate_,
	|	WorkOutputActivityKinds.ReferenceOrder.Number,
	|	WorkOutputActivityKinds.ReferenceOrder.Date,
	|	WorkOutputActivityKinds.WorkKind.UnitOfMeasure,
	|	CASE
	|		WHEN WorkOutputActivityKinds.ReferenceOrder REFS Document.RMOrder
	|			THEN &SynonymForRepairOrder
	|		WHEN TRUE
	|			THEN """"
	|	END 
	|
	|ORDER BY
	|	Ref,
	|	LineNumber,
	|	WorkKind
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeeDevelopmentEmployees.Employee_.Code AS EmployeeCode_,
	|	EmployeeDevelopmentEmployees.Employee_.Description AS EmployeeFULLName,
	|	UNDEFINED AS WorkKind,
	|	SUM(EmployeeDevelopmentEmployees.LPR) AS LPR,
	|	SUM(EmployeeDevelopmentEmployees.TariffRate) AS Rate1,
	|	SUM(EmployeeDevelopmentEmployees.HoursWorked) AS Time,
	|	SUM(EmployeeDevelopmentEmployees.Sum) AS Sum,
	|	EmployeeDevelopmentEmployees.Ref AS Ref,
	|	UNDEFINED AS OrderNumber__,
	|	UNDEFINED AS Order_Date,
	|	UNDEFINED AS TypeOfOrder_,
	|	EmployeeDevelopmentEmployees.LineNumber AS LineNumber
	|FROM
	|	Document.WorkOutput.Employees AS EmployeeDevelopmentEmployees
	|WHERE
	|	EmployeeDevelopmentEmployees.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	EmployeeDevelopmentEmployees.Employee_.Code,
	|	EmployeeDevelopmentEmployees.Employee_.Description,
	|	EmployeeDevelopmentEmployees.Ref,
	|	EmployeeDevelopmentEmployees.LineNumber
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Employee_.Code AS EmployeeCode_,
	|	DD.Employee_.Description AS EmployeeFULLName,
	|	DD.WorkKind AS WorkKind,
	|	0 AS LPR,
	|	0 AS TariffRate,
	|	0 AS HoursWorked,
	|	SUM(DD.Sum) AS Sum,
	|	DD.Ref AS Ref,
	|	DD.ReferenceOrder.Number AS OrderNumber__,
	|	DD.ReferenceOrder.Date AS Order_Date,
	|	CASE
	|		WHEN DD.ReferenceOrder REFS Document.RMOrder
	|			THEN &SynonymForRepairOrder
	|		WHEN DD.ReferenceOrder REFS Document.ProductionStage2_2
	|			THEN &StageSynonym
	|		WHEN DD.ReferenceOrder REFS Document.BackflushProduction
	|			THEN &SynonymForProductionWithoutOrder
	|		WHEN TRUE
	|			THEN """"
	|	END AS TypeOfOrder_,
	|	DD.LineNumber AS LineNumber
	|FROM
	|	Document.WorkOutput.ActivityKinds AS DD
	|WHERE
	|	DD.Ref IN(&ObjectsArray)
	|	AND (NOT DD.Ref.AutoAllocation AND DD.Ref.WorkOrderKind IN (VALUE(Enum.TeamWorkOrderKinds.TeamByOrder21),
	|												VALUE(Enum.TeamWorkOrderKinds.TeamWithoutOrder21),
	|												VALUE(Enum.TeamWorkOrderKinds.OtherActivities),
	|												VALUE(Enum.TeamWorkOrderKinds.Repair))
	|		OR DD.Ref.WorkOrderKind = VALUE(Enum.TeamWorkOrderKinds.Personal))
	|
	|GROUP BY
	|	DD.Employee_.Code,
	|	DD.Employee_.Description,
	|	DD.WorkKind,
	|	DD.Ref,
	|	DD.ReferenceOrder.Number,
	|	DD.ReferenceOrder.Date,
	|	CASE
	|		WHEN DD.ReferenceOrder REFS Document.RMOrder
	|			THEN &SynonymForRepairOrder
	|		WHEN DD.ReferenceOrder REFS Document.ProductionStage2_2
	|			THEN &StageSynonym
	|		WHEN DD.ReferenceOrder REFS Document.BackflushProduction
	|			THEN &SynonymForProductionWithoutOrder
	|		WHEN TRUE
	|			THEN """"
	|	END,
	|	DD.LineNumber
	|
	|ORDER BY
	|	LineNumber,
	|	Ref,
	|	EmployeeFULLName
	|TOTALS
	|	MAX(EmployeeFULLName),
	|	MIN(LineNumber),
	|	SUM(Sum)
	|BY
	|	Ref,
	|	EmployeeCode_";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("SynonymForItinerary", NStr("vi = 'Sơ đồ quy trình';
													|ru = 'Маршрутный лист';
													|en = 'Operation sheet'; fa = 'برگه عملیات';
													|it = 'Foglio di lavorazione';
													|pl = 'Karta przebiegu materiału';
													|tr = 'İşlem listesi'", Common.DefaultLanguageCode()));
	Query.SetParameter("SynonymForRepairOrder", NStr("vi = 'Đơn hàng sửa chữa';
													|ru = 'Заказ на ремонт';
													|en = 'R&M order'; fa = 'سفارش تعمیر و نگهداری';
													|it = 'Ordine di manutenzione';
													|pl = 'Zamówienie naprawy';
													|tr = 'Bakım-onarım siparişi'", Common.DefaultLanguageCode()));
	Query.SetParameter("StageSynonym", NStr("vi = 'Công đoạn';
											|ru = 'Этап';
											|en = 'Stage'; fa = 'مرحله';
											|it = 'Fase';
											|pl = 'Stage';
											|tr = 'Aşama'"));
	Query.SetParameter("SynonymForProductionWithoutOrder", NStr("vi = 'Sản xuất không theo đơn đặt hàng';
																|ru = 'Производство без заказа';
																|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
																|it = 'Produzione senza ordine';
																|pl = 'Produkcja bez zamówień';
																|tr = 'Geriye dönük üretim'", Common.DefaultLanguageCode()));
	
	Result = Query.ExecuteBatch();
	
	SelectionByDocuments = Result[0].Select();
	SelectionByTypeOfWork = Result[1].Select(QueryResultIteration.ByGroups);
	SamplingByEmployees = Result[2].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	Template = PrintManagement.PrintFormTemplate("Document.WorkOutput.PF_MXL_WorkOutput");
	SectionHeader = Template.GetArea("Header");
	BrigadeCapArea = Template.GetArea("BrigadeCap");
	
	ScopeNameOfJobTypesTable = Template.GetArea("TableName_CompletedWorks");
	
	AreaTitleOfTableOfTypesOfWork = Template.GetArea("TableTitle_CompletedWorks");
	AreaRowOfTableOfTypesOfWork = Template.GetArea("Line_CompletedWorks");
	
	AreaTitleOfTableOfTypesOfWorkWithoutOrder = Template.GetArea("TableTitle_CompletedWorks_WithoutOrder");
	AreaRowOfTableOfTypesOfWorkWithoutOrder = Template.GetArea("Line_CompletedWorks_WithoutOrder");
	
	ScopeOfTableOfTypesOfWork = Template.GetArea("Summary_CompletedWorks");
	
	AreaNameOfEmployeesTable = Template.GetArea("Name__Employees");
	
	BasementArea = Template.GetArea("Footer");
	
	While SelectionByDocuments.Next() Do
		
		// Table of completed works.
		If Not SelectionByTypeOfWork.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		SamplingByTSLines = SelectionByTypeOfWork.Select();
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		SectionHeader.Parameters.Fill(SelectionByDocuments);
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert(
			"DocumentNumber",
			ObjectsPrefixesClientServer.NumberForPrinting(
				SelectionByDocuments.DocumentNumber,
				False,
				True));
		SectionHeader.Parameters.Fill(AreaParameters_);
		
		SpreadsheetDocument.Put(SectionHeader);
		
		If ValueIsFilled(SelectionByDocuments.Team) Then
			BrigadeCapArea.Parameters.Fill(SelectionByDocuments);
			SpreadsheetDocument.Put(BrigadeCapArea);
		EndIf;
		
		FormatString = StrTemplate("DF='MMMM yyyy'; L =%1", Common.DefaultLanguageCode());
	
		AreaParameters_ = New Structure;
		AreaParameters_.Insert("Month", Format(SelectionByDocuments.Month, FormatString));
		
		ScopeNameOfJobTypesTable.Parameters.Fill(AreaParameters_);
		
		SpreadsheetDocument.Put(ScopeNameOfJobTypesTable);
		
		If SelectionByDocuments.ByReferences Then
			AreaTitleOfTableOfTypesOfWork.Parameters.Fill(SelectionByDocuments);
			SpreadsheetDocument.Put(AreaTitleOfTableOfTypesOfWork);
		Else
			AreaTitleOfTableOfTypesOfWorkWithoutOrder.Parameters.Fill(SelectionByDocuments);
			SpreadsheetDocument.Put(AreaTitleOfTableOfTypesOfWorkWithoutOrder);
		EndIf;
		
		While SamplingByTSLines.Next() Do
			
			If SelectionByDocuments.ByReferences Then
				
				AreaRowOfTableOfTypesOfWork.Parameters.Fill(SamplingByTSLines);
				
				AreaParameters_ = New Structure;
				AreaParameters_.Insert(
					"OrderNumber__",
					ObjectsPrefixesClientServer.NumberForPrinting(
						SamplingByTSLines.OrderNumber__,
						False,
						True));
				AreaParameters_.Insert("Order_Date", Format(SamplingByTSLines.Order_Date, "DLF=D"));
				AreaRowOfTableOfTypesOfWork.Parameters.Fill(AreaParameters_);
				
				SpreadsheetDocument.Put(AreaRowOfTableOfTypesOfWork);
				
			Else
				AreaRowOfTableOfTypesOfWorkWithoutOrder.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Put(AreaRowOfTableOfTypesOfWorkWithoutOrder);
			EndIf;
			
		EndDo;
		
		ScopeOfTableOfTypesOfWork.Parameters.Fill(SelectionByTypeOfWork);
		SpreadsheetDocument.Put(ScopeOfTableOfTypesOfWork);
		
		// The Employees table.
		If Not SamplingByEmployees.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		If SelectionByDocuments.AreaSuffix = "Auto" Then
			AreaNameTitle = "TabTitle_Employees_Auto";
			AreaNameString    = "Line_Employees_Auto";
			AreaNameTotal      = "Total_Employees_Auto";
		Else
			AreaNameTitle = "TabTitle___NotAuto";
			AreaNameString    = "String___NotAuto";
			AreaNameTotal      = "BottomLine_Employees_NotAuto";
		EndIf;
		
		AreaHeaderOfEmployeesTable = Template.GetArea(AreaNameTitle);
		AreaRowOfEmployeesTable    = Template.GetArea(AreaNameString);
		TableSummaryAreaEmployees      = Template.GetArea(AreaNameTotal);
		
		SamplingByTSLines = SamplingByEmployees.Select(QueryResultIteration.ByGroups);
		
		SpreadsheetDocument.Put(AreaNameOfEmployeesTable);
		
		AreaHeaderOfEmployeesTable.Parameters.Fill(SelectionByDocuments);
		SpreadsheetDocument.Put(AreaHeaderOfEmployeesTable);
		
		LineNumber = 1;
		While SamplingByTSLines.Next() Do
			
			Selection = SamplingByTSLines.Select();
			DisplaySummaryAreaOfEmployeeTable = False;
			
			If SelectionByDocuments.AreaSuffix = "NotAuto" Then
				
				TableSummaryAreaEmployee = Template.GetArea("BottomLine_Employee_NotAuto");
				TableSummaryAreaEmployee.Parameters.Fill(SamplingByTSLines);
				
				AreaParameters_ = New Structure;
				AreaParameters_.Insert("LineNumber", LineNumber);
				TableSummaryAreaEmployee.Parameters.Fill(AreaParameters_);
				
				LineNumber = LineNumber + 1;
				DisplaySummaryAreaOfEmployeeTable = True;
			EndIf;
			
			While Selection.Next() Do
				
				If DisplaySummaryAreaOfEmployeeTable Then
					
					TableSummaryAreaEmployee.Parameters.Fill(Selection);
					
					If SelectionByDocuments.AreaSuffix = "NotAuto" Then
						
						AreaParameters_ = New Structure;
						AreaParameters_.Insert(
							"OrderNumber__",
							ObjectsPrefixesClientServer.NumberForPrinting(
								Selection.OrderNumber__,
								False,
								True));
						AreaParameters_.Insert("Order_Date", Format(Selection.Order_Date, "DLF=D"));
						TableSummaryAreaEmployee.Parameters.Fill(AreaParameters_);
						
					EndIf;
					
					SpreadsheetDocument.Put(TableSummaryAreaEmployee);
					
					DisplaySummaryAreaOfEmployeeTable = False;
					
				Else
					
					AreaRowOfEmployeesTable.Parameters.Fill(Selection);
					
					If SelectionByDocuments.AreaSuffix = "NotAuto" Then
						
						AreaParameters_ = New Structure;
						AreaParameters_.Insert(
							"OrderNumber__",
							ObjectsPrefixesClientServer.NumberForPrinting(
								Selection.OrderNumber__,
								False,
								True));
						AreaParameters_.Insert("Order_Date", Format(Selection.Order_Date, "DLF=D"));
						AreaRowOfEmployeesTable.Parameters.Fill(AreaParameters_);
						
					EndIf;
					
					SpreadsheetDocument.Put(AreaRowOfEmployeesTable);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		TableSummaryAreaEmployees.Parameters.Fill(SamplingByEmployees);
		SpreadsheetDocument.Put(TableSummaryAreaEmployees);
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert(
			"Manager",
			PersonsTM.IndividualShortName(
				SelectionByDocuments.Manager,
				SelectionByDocuments.DocumentDate));
		BasementArea.Parameters.Fill(AreaParameters_);
		
		SpreadsheetDocument.Put(BasementArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// 
// Parameters:
// 	ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.WorkOutput.Form.DocumentsListForm";
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.WorkOutput))
		And AccessRight("Insert", Metadata.Documents.WorkOutput)
		And AccessRight("Read",     Metadata.AccumulationRegisters.LaborCostsToRegister)
		And Not GetFunctionalOption("TradeManagement");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS DevelopmentOfEmployeesLaborCostsForRegistration
	|FROM
	|	(SELECT
	|		LaborCostsToRegister.WorkKind AS WorkKind,
	|		LaborCostsToRegister.Organization AS Organization,
	|		LaborCostsToRegister.Performer AS Performer,
	|		LaborCostsToRegister.ReferenceOrder AS ReferenceOrder,
	|		LaborCostsToRegister.Department AS Department
	|	FROM
	|		AccumulationRegister.LaborCostsToRegister.Balance(, ) AS LaborCostsToRegister
	|		INNER JOIN Catalog.BusinessStructure AS Departments
	|			ON Departments.Ref = LaborCostsToRegister.Department
	|		INNER JOIN Catalog.Companies AS Companies
	|			ON Companies.Ref = LaborCostsToRegister.Organization
	|	
	|	GROUP BY
	|		LaborCostsToRegister.ReferenceOrder,
	|		LaborCostsToRegister.Performer,
	|		LaborCostsToRegister.WorkKind,
	|		LaborCostsToRegister.Organization,
	|		LaborCostsToRegister.Department) AS NestedQuery";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Development of employees
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "WorkOutput";
	UserTaskParent.Presentation  = NStr("vi = 'Sản lượng của nhân viên';
										|ru = 'Выработка сотрудников';
										|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
										|it = 'Produttività dei dipendenti';
										|pl = 'Ustawienia wydajności pracowników';
										|tr = 'Zaman çizelgesi bazlı ücretlendirme'");
	UserTaskParent.HasToDoItems       = Result.DevelopmentOfEmployeesLaborCostsForRegistration > 0;
	UserTaskParent.Owner       = Metadata.Subsystems.Production;
	
	// DevelopmentOfEmployeesLaborCostsForRegistration
	FilterParameters = New Structure;
	FilterParameters.Insert("Team", Catalogs.Teams.EmptyRef());
	FilterParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	FilterParameters.Insert("WorkOrderKind", Enums.TeamWorkOrderKinds.EmptyRef());
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("CurrentPageName", "GroupLaborCostsForRegistration");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "DevelopmentOfEmployeesLaborCostsForRegistration";
	ToDoItem.HasToDoItems       = Result.DevelopmentOfEmployeesLaborCostsForRegistration > 0;
	ToDoItem.Presentation  = NStr("vi = 'Chuẩn bị lập chi phí nhân công ';
									|ru = 'Трудозатраты к оформлению';
									|en = 'Labor costs to register'; fa = 'هزینه‌های دستمزد قابل ثبت';
									|it = 'Costi di manodopera da registrare';
									|pl = 'Zarządzanie pracą do sporządzenia';
									|tr = 'Düzenlenecek iş gücü maliyetleri'");
	ToDoItem.Count     = Result.DevelopmentOfEmployeesLaborCostsForRegistration;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "WorkOutput";
	
EndProcedure

#EndRegion

#Region CreatingHyperlinkInProductionLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.WorkOutput) Then
		Return Undefined;
	EndIf;
	
	ToRegister = LaborCostsToRegister(Parameters);
	
	Selection = ToRegister.Select();
	
	HyperlinkText = NStr("vi = 'Sản lượng của nhân viên';
						|ru = 'Выработка сотрудников';
						|en = 'Timesheets charge'; fa = 'محاسبه برگه‌های کارکرد';
						|it = 'Produttività dei dipendenti';
						|pl = 'Ustawienia wydajności pracowników';
						|tr = 'Zaman çizelgesi bazlı ücretlendirme'");
	If Not Selection.Next() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			"Document.WorkOutput.Form.DocumentsListForm");
	Else
		Return New FormattedString(HyperlinkText,,,,
			"Document.WorkOutput.Form.DocumentsListForm");
	EndIf;
	
EndFunction

#EndRegion

#Region Other

Procedure SaveNewDocument(CurrentDocument, DocumentsList, ErrorList)
	
	If CurrentDocument = Undefined Then
		Return;
	EndIf;
	
	FillWorkers(CurrentDocument);
	
	CurrentDocument.Write(DocumentWriteMode.Write);
	
	If CurrentDocument.CheckFilling() Then
		Try
			CurrentDocument.Write(DocumentWriteMode.Posting);
		Except
			AddAutomaticCreationError(CurrentDocument, ErrorList, "Posting", ErrorDescription());
		EndTry;
	Else
		AddAutomaticCreationError(CurrentDocument, ErrorList, "FillType");
	EndIf;
	
	For Each CurMessage In GetUserMessages(True) Do
		
		ErrorStructure = New Structure();
		ErrorStructure.Insert("Organization", CurrentDocument.Organization);
		ErrorStructure.Insert("Document", CurrentDocument.Ref);
		ErrorStructure.Insert("ErrorText", CurMessage.Text);
		ErrorStructure.Insert("ErrorType", "UserMessages");
		
		ErrorList.Add(ErrorStructure);
		
	EndDo;
	
	DocumentsList.Add(CurrentDocument.Ref);
	
EndProcedure

Procedure AddAutomaticCreationError(Document, ErrorList, ErrorType, ErrorDescription = "")
	
	If ErrorType = "FillType" Then
		If Document.WorkOrderKind = Enums.TeamWorkOrderKinds.Personal Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi điền đơn đặt hàng cá nhân trong khoảng thời gian từ %1 đến %2 cho Doanh nghiệp ""%3"" và bộ phận ""%4"".';
					|ru = 'Ошибка заполнения персонального наряда за период с %1 по %2 по организации ""%3"" и подразделению ""%4"".';
					|en = 'An error occurred while filling in the personal work order for the period from %1 to %2 by ""%3"" company and ""%4"" business unit.'; fa = 'An error occurred while filling in the personal work order for the period from %1 to %2 by ""%3"" company and ""%4"" business unit.';
					|it = 'Errore di compilazione della commessa personale per il periodo dal %1 al %2 per la società ""%3"" e reparto ""%4"".';
					|pl = 'Błąd wypełnienia zlecenia personalnego od %1 do %2 według firmy ""%3"" i działu ""%4"".';
					|tr = '""%4"" departmanı ve ""%3"" iş yerine göre %1 ile %2 arasındaki dönem için kişisel emrin doldurulma hatası.'", Common.DefaultLanguageCode()),
				Format(BegOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Format(EndOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Document.Organization,
				Document.Department);
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi điền vào thứ tự đội trong khoảng thời gian từ %1 đến %2 cho Doanh nghiệp ""%3"", đội ""%4"" và Bộ phận ""%5"".';
					|ru = 'Ошибка заполнения бригадного наряда за период с %1 по %2 по организации ""%3"", бригаде ""%4"" и подразделению ""%5"".';
					|en = 'An error occurred while filling in the team work order for the period from %1 to %2 of the ""%3"" company, ""%4"" team and ""%5"" business unit.'; fa = 'An error occurred while filling in the team work order for the period from %1 to %2 of the ""%3"" company, ""%4"" team and ""%5"" business unit.';
					|it = 'Errore di compilazione della commessa a squadra per il periodo dal %1 al %2 per la società ""%3"", squadra ""%4"" e reparto ""%5"".';
					|pl = 'Błąd wypełnienia zlecenia brygadowego za okres od %1 do %2 według firmy ""%3"", dla brygady ""%4"" i dla działu ""%5"".';
					|tr = '""%5"" departmanı, ""%4"" çalışma ekibi ve ""%3"" iş yerine göre %1 ile %2 arasındaki dönem için çalışma ekibi emrinin doldurulma hatası.'", Common.DefaultLanguageCode()),
				Format(BegOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Format(EndOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Document.Organization,
				Document.Team,
				Document.Department);
		EndIf;
	ElsIf ErrorType = "Posting" Then
		If Document.WorkOrderKind = Enums.TeamWorkOrderKinds.Personal Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi thực hiện một đơn đặt hàng cá nhân trong khoảng thời gian từ %1 đến %2 cho Doanh nghiệp ""%3"" và bộ phận ""%4"": %5.';
					|ru = 'Ошибка проведения персонального наряда за период с %1 по %2 по организации ""%3"" и подразделению ""%4"": %5.';
					|en = 'An error occurred while posting the personal work order for the period from %1 till %2 by company ""%3"" and business unit ""%4"": %5.'; fa = 'An error occurred while posting the personal work order for the period from %1 till %2 by company ""%3"" and business unit ""%4"": %5.';
					|it = 'Errore di registrazione della commessa personale per il periodo dal %1 al %2 per la società ""%3"" e reparto ""%4"": %5.';
					|pl = 'Błąd zatwierdzenia zlecenia personalnego za okres od %1 do %2 według firmy ""%3"" i działu ""%4"": %5.';
					|tr = '""%4"" departmanı ve ""%3"" iş yerine göre %1 ile %2 arasındaki dönem için kişisel emrin kaydedilme hatası: %5.'", Common.DefaultLanguageCode()),
				Format(BegOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Format(EndOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Document.Organization,
				Document.Department,
				ErrorDescription);
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi thực hiện lệnh đội trong khoảng thời gian từ %1 đến %2 cho Doanh nghiệp ""%3"", đội ""%4"" và Bộ phận ""%5"": %6.';
					|ru = 'Ошибка проведения бригадного наряда за период с %1 по %2 по организации ""%3"", бригаде ""%4"" и подразделению ""%5"": %6.';
					|en = 'An error occurred while posting the team work order for the period from %1 to %2 of the ""%3"" company, ""%4"" team and ""%5"" business unit: %6.'; fa = 'An error occurred while posting the team work order for the period from %1 to %2 of the ""%3"" company, ""%4"" team and ""%5"" business unit: %6.';
					|it = 'Errore di registrazione della commessa a squadra per il periodo dal %1 al %2 per la società ""%3"", squadra ""%4"" e reparto ""%5"": %6.';
					|pl = 'Błąd zatwierdzenia zlecenia brygadowego za okres od %1 do %2 według firmy ""%3"", brygady ""%4"" i działa ""%5"": %6.';
					|tr = '""%5"" departmanı, ""%4"" çalışma ekibi ve ""%3"" iş yerine göre %1 ile %2 arasındaki dönem için çalışma ekibi emrinin kaydedilme hatası: %6.'", Common.DefaultLanguageCode()),
				Format(BegOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Format(EndOfMonth(Document.Month),"DLF=dd.MM.yyyy"),
				Document.Organization,
				Document.Team,
				Document.Department,
				ErrorDescription);
		EndIf;
	ElsIf ErrorType = "DeletingDocument" Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xóa chứng từ %1 do: %2.';
				|ru = 'Не удалось удалить документ %1 по причине: %2.';
				|en = 'Cannot delete the document: %1. Reason: %2.'; fa = 'Cannot delete the document: %1. Reason: %2.';
				|it = 'Non è stato possibile cancellare il documento %1 a causa di: %2.';
				|pl = 'Nie udało się usunąć dokument %1 z powodu: %2.';
				|tr = '%1 belgesinin silinememe nedeni: %2.'", Common.DefaultLanguageCode()),
			Document.Ref,
			ErrorDescription);
	EndIf;
	
	ErrorStructure = New Structure();
	ErrorStructure.Insert("Organization", Document.Organization);
	ErrorStructure.Insert("Document", Document.Ref);
	ErrorStructure.Insert("ErrorText", ErrorText);
	ErrorStructure.Insert("ErrorType", ErrorType);
	
	ErrorList.Add(ErrorStructure);
	
EndProcedure

Function Brigades(Period, Teams)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	MAX(WorkOutput.Date) AS Date,
	|	WorkOutput.Team AS Team
	|INTO TTDateOfRelevance
	|FROM
	|	Document.WorkOutput AS WorkOutput
	|WHERE
	|	WorkOutput.Date <= &Period
	|	AND WorkOutput.Team IN(&Teams)
	|	AND WorkOutput.Posted
	|
	|GROUP BY
	|	WorkOutput.Team
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(WorkOutput.Ref) AS Ref,
	|	TTDateOfRelevance.Team AS Team
	|INTO CompositionDocuments
	|FROM
	|	TTDateOfRelevance AS TTDateOfRelevance
	|		INNER JOIN Document.WorkOutput AS WorkOutput
	|		ON TTDateOfRelevance.Date = WorkOutput.Date
	|			AND TTDateOfRelevance.Team = WorkOutput.Team
	|WHERE
	|	WorkOutput.Posted
	|
	|GROUP BY
	|	TTDateOfRelevance.Team
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CompositionDocuments.Team AS Team,
	|	Employees.Employee_ AS Employee_,
	|	Employees.Employee AS Employee,
	|	SUM(Employees.LPR) AS LPR
	|FROM
	|	CompositionDocuments AS CompositionDocuments
	|		INNER JOIN Document.WorkOutput.Employees AS Employees
	|		ON CompositionDocuments.Ref = Employees.Ref
	|
	|GROUP BY
	|	CompositionDocuments.Team,
	|	Employees.Employee_,
	|	Employees.Employee
	|TOTALS BY
	|	Team";
	
	Query.SetParameter("Teams", Teams);
	Query.SetParameter("Period", Period);
	
	Result = Query.Execute();
	
	Return Result.Select(QueryResultIteration.ByGroups);
	
EndFunction

Function MixedArtistType(Object)
	
	If Not Object.AccountingForLaborCostsByEmployees Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	TRUE
	|FROM
	|	Document.BackflushProduction AS DocumentAttributes
	|	
	|	INNER JOIN Constants AS Constants
	|	ON TRUE
	|
	|WHERE
	|	DocumentAttributes.Ref IN(&References)
	|	AND DocumentAttributes.Date < Constants.StartDateOfRecordKeepingOfLaborCostsForEmployees
	|";
	Query.SetParameter("References", Object.ActivityKinds.Unload(, "ReferenceOrder").UnloadColumn("ReferenceOrder"));
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndRegion

#EndIf
