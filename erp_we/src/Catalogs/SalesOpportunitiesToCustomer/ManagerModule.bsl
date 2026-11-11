#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTableRow   - description of the creation command based on.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Catalogs.SalesOpportunitiesToCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Catalogs.SalesOpportunitiesToCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Catalogs.SalesOpportunitiesToCustomer);
		CreateBasedOnCommand.FunctionalOptions = "UseSalesOpportunitiesToCustomer";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Populates the list of creation commands based on.
// 
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.CustomerInvoiceServices.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.SalesOrder.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.PurchaseOrder.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.TransferOfGoodsToBailee.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.RequestForReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.CommercialProposalForCustomer.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.GoodsShipmentToCustomer.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Command = Documents.CustomerInvoice.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	
	Command = Documents.MaterialProviderOrder2_5.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Used in the interaction mechanism. Returns the client and participants of the transaction
//
//
// Parameters:
//  Ref  - CatalogRef.SalesOpportunitiesToCustomer - the transaction for which contacts are received.
//
// Returns:
//   Array   - an array containing contacts.
//
Function GetContacts(Ref) Export

	Return SalesOpportunitiesServer.GetParticipantsOnTabularPartOfSubjectOfInteraction(
		Ref, Common.ObjectAttributeValue(Ref,"Partner"));

EndFunction

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array - a list of the names of the object's details.
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	
	Result.Add("Description");
	Result.Add("Code");
	Result.Add("PrimaryDemandCurrency");
	Result.Add("StartDate");
	Result.Add("EndDate");
	Result.Add("Comment");
	Result.Add("EnabledGoodsAssignmentInSalesOpportunity");
	Result.Add("EmployeeResponsible");
	Result.Add("PotentialSaleAmount");
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Partner, EmptyRef AS TRUE)";

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

#EndRegion

#Region Private

#Region ToDoList

// Fills in the user's to-do list.
//
// Parameters:
//   ToDoList - ValueTable - 
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Catalog.SalesOpportunitiesToCustomer.Form.ListForm";
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Catalogs.SalesOpportunitiesToCustomer))
		And AccessRight("Update", Metadata.Catalogs.SalesOpportunitiesToCustomer)
		And GetFunctionalOption("UseSalesOpportunitiesToCustomer");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT SalesOpportunitiesToCustomer.Ref) AS CustomerTransactionsAreAllInWorks
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|WHERE
	|	SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.InProgress)
	|	AND SalesOpportunitiesToCustomer.EmployeeResponsible = &User
	|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
	|	AND (NOT SalesOpportunitiesToCustomer.Closed_)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// dealingsclients
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "SalesOpportunitiesToCustomer";
	UserTaskParent.HasToDoItems       = Result.CustomerTransactionsAreAllInWorks > 0;
	UserTaskParent.Presentation  = NStr("vi = 'Vụ việc với khách hàng';
										|ru = 'Сделки с клиентами';
										|en = 'Sales opportunities'; fa = 'فرصت‌های فروش';
										|it = 'Affari con i clienti';
										|pl = 'Umowy z klientami';
										|tr = 'Müşterilerle satış fırsatları'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// CustomerTransactionsAreAllInWorks
	FilterParameters = New Structure;
	FilterParameters.Insert("Status", "InProgress");
	FilterParameters.Insert("OnlyClient", True);
	FilterParameters.Insert("EmployeeResponsible", CommonQueryParameters.User);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "CustomerTransactionsAreAllInWorks";
	ToDoItem.HasToDoItems       = Result.CustomerTransactionsAreAllInWorks > 0;
	ToDoItem.Presentation  = NStr("vi = 'Tổng số vụ việc đang làm việc';
									|ru = 'Всего сделок в работе';
									|en = 'Total sales opportunities in progress'; fa = 'Total sales opportunities in progress';
									|it = 'Totale transazioni in corso';
									|pl = 'Łącznie transakcji w toku';
									|tr = 'Devam eden tüm satış fırsatları'");
	ToDoItem.Count     = Result.CustomerTransactionsAreAllInWorks;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "SalesOpportunitiesToCustomer";
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.PriceAnalysis.AddReportCommand(ReportsCommands, "SalesOpportunitiesToCustomer");
	
	Reports.SaleContent.AddReportCommand(ReportsCommands);
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#EndRegion

#EndRegion

#EndIf


