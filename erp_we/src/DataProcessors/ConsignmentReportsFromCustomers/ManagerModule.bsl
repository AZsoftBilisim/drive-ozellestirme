#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

#Region CreatingHyperlinkInSalesLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	ShowOrders = GetFunctionalOption("UseSalesCommission")
		And AccessRight("Read", Metadata.Documents.ConsignmentReportFromCustomer)
		And AccessRight("Use", Metadata.DataProcessors.ConsignmentReportsFromCustomers);
		
	Hyperlink = Undefined;
	HyperlinkText = NStr("vi = 'Bảng kê hàng hóa của người nhận ký gửi/bán hàng thông qua người nhận ký gửi';
						|ru = 'Отчеты комиссионеров/реализации через комиссионеров';
						|en = 'Consignment issue notifications or sales via consignees'; fa = 'Consignment issue notifications or sales via consignees';
						|it = 'Report commissionari/vendite tramite commissionario';
						|pl = 'Raporty komisantów/sprzedaży przez komisantów';
						|tr = 'Konsinye raporları/konsinye aracılığıyla satışlar'");
	
	If ShowOrders Then
		Hyperlink = New FormattedString(HyperlinkText,,,,
			NameOfCommissionAgentReportsListForm());
	EndIf;
	
	Return Hyperlink;
	
EndFunction

Function NameOfCommissionAgentReportsListForm() Export
	
	Return "DataProcessor.ConsignmentReportsFromCustomers.Form.RegisterConsignmentReportsOrSalesViaCommissionAgents";
	
EndFunction

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export

	Result = New Structure("ToRegister, SeeAlsoInProgress");

	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.ConsignmentReportFromCustomer");
	ArrayCalculationManagersSeeAlsoInWork.Add("Document.CustomerInvoice");
	
	Result.SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, Parameters[0]);

	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = Metadata.DataProcessors.ConsignmentReportsFromCustomers.Forms.DocumentsList.FullName();
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.ConsignmentReportFromCustomer))
		And (AccessRight("Insert", Metadata.Documents.ConsignmentReportFromCustomer)
			Or AccessRight("Insert", Metadata.Documents.WriteOffReportFromCommissionAgent))
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsTransferredToCommissionAgent)
		And GetFunctionalOption("UseSalesCommission");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(*) AS ReportsOfCommissionersAreRequiredToIssue
	|FROM
	|	(SELECT DISTINCT
	|		GoodsTransferred.Organization AS Organization,
	|		GoodsTransferred.ItemsLocationAttributes.StorageLocation AS Consignee,
	|		GoodsTransferred.Terms AS Terms
	|	FROM
	|		AccumulationRegister.GoodsTransferredToCommissionAgent.Balance(,
	|															ItemsLocationAttributes.StorageLocation <> VALUE(Catalog.Partners.OurEnterprise)
	|															AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)) AS GoodsTransferred
	|	) AS AccountSalesFromCommissionAgents";
	
	Result = ToDoListServer.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Commissionersreferences
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "AccountSalesFromCommissionAgents";
	UserTaskParent.Presentation  = NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
										|ru = 'Отчеты комиссионеров';
										|en = 'Consignment issue notifications'; fa = 'اعلامیه‌های ارسال امانی';
										|it = 'report dei commissionari';
										|pl = 'Raporty komisantów';
										|tr = 'Konsinye raporları'");
	UserTaskParent.HasToDoItems       = Result.ReportsOfCommissionersAreRequiredToIssue > 0;
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// ReportsOfCommissionersAreRequiredToIssue
	FilterParameters = New Structure;
	FilterParameters.Insert("Consignee", Catalogs.Partners.EmptyRef());
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("CurrentPageName", "TheCommissionAgentsPage");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ReportsOfCommissionersAreRequiredToIssue";
	ToDoItem.HasToDoItems       = Result.ReportsOfCommissionersAreRequiredToIssue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Cần lập bảng kê';
									|ru = 'Требуется оформить';
									|en = 'To register'; fa = 'برای ثبت';
									|it = 'Da formalizzare';
									|pl = 'Należy sporządzić';
									|tr = 'Düzenleme gerekli'");
	ToDoItem.Count     = Result.ReportsOfCommissionersAreRequiredToIssue;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "AccountSalesFromCommissionAgents";
	
EndProcedure

#EndRegion

Function DefaultFormAssignmentKey() Export
	
	Return "DocumentsReportsOfCommissionAgents";
	
EndFunction

#EndRegion

#EndIf