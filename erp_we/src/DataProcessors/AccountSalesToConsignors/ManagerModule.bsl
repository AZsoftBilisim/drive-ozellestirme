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

#EndRegion

#EndRegion

#Region Private

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = Metadata.DataProcessors.AccountSalesToConsignors.Forms.DocumentsList.FullName();
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.ConsignmentReportToVendor))
		And (AccessRight("Insert", Metadata.Documents.ConsignmentReportToVendor)
			Or AccessRight("Insert", Metadata.Documents.PurchaseInvoiceConsignmentStockLost))
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor)
		And GetFunctionalOption("UsePurchaseCommission");
		
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(NestedQuery.DocumentsCount) AS ReportsToCommitteesAreRequiredToIssue
	|FROM
	|	(SELECT
	|		NestedQuery.BusinessOperation AS BusinessOperation,
	|		NestedQuery.WriteOffPeriod AS WriteOffPeriod,
	|		NestedQuery.Currency AS Currency,
	|		NestedQuery.Organization AS Organization,
	|		NestedQuery.GoodsOwner AS GoodsOwner,
	|		NestedQuery.Counterparty AS Counterparty,
	|		NestedQuery.Terms AS Terms,
	|		NestedQuery.Contract AS Contract,
	|		NestedQuery.VATTaxation AS VATTaxation,
	|		1 AS DocumentsCount
	|	FROM
	|		(SELECT
	|			0 AS BusinessOperation,
	|			NULL AS WriteOffPeriod,
	|			GoodsForRegistration.Currency AS Currency,
	|			GoodsForRegistration.InventoryOwnerAttribute.Organization AS Organization,
	|			GoodsForRegistration.InventoryOwnerAttribute.GoodsOwner AS GoodsOwner,
	|			GoodsForRegistration.InventoryOwnerAttribute.Counterparty AS Counterparty,
	|			GoodsForRegistration.InventoryOwnerAttribute.Terms AS Terms,
	|			GoodsForRegistration.InventoryOwnerAttribute.Contract AS Contract,
	|			GoodsForRegistration.InventoryOwnerAttribute.VATTaxation AS VATTaxation,
	|			SUM(GoodsForRegistration.QuantityConsumedForIncoiceRegistrationBalance) AS Count
	|		FROM
	|			AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(, ) AS GoodsForRegistration
	|		WHERE
	|			GoodsForRegistration.InventoryOwnerAttribute.GoodsOwner REFS Catalog.Partners
	|			AND GoodsForRegistration.QuantityConsumedForIncoiceRegistrationBalance <> 0
	|
	|		GROUP BY
	|			0,
	|			GoodsForRegistration.Currency,
	|			GoodsForRegistration.InventoryOwnerAttribute.Organization,
	|			GoodsForRegistration.InventoryOwnerAttribute.GoodsOwner,
	|			GoodsForRegistration.InventoryOwnerAttribute.Counterparty,
	|			GoodsForRegistration.InventoryOwnerAttribute.Terms,
	|			GoodsForRegistration.InventoryOwnerAttribute.Contract,
	|			GoodsForRegistration.InventoryOwnerAttribute.VATTaxation
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			0 AS BusinessOperation,
	|			NULL,
	|			ServicesForRegistration.Currency,
	|			ServicesForRegistration.Organization,
	|			Partner.Ref,
	|			UNDEFINED AS Counterparty,
	|			ServicesForRegistration.Terms,
	|			UNDEFINED,
	|			UNDEFINED,
	|			NULL
	|		FROM
	|			AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(, ) AS ServicesForRegistration
	|				INNER JOIN Catalog.Partners AS Partner
	|				ON ServicesForRegistration.ItemsLocationAttributes.Partner = Partner.Ref
	|		WHERE
	|			ServicesForRegistration.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|		
	|		GROUP BY
	|			1,
	|			ServicesForRegistration.Currency,
	|			ServicesForRegistration.Organization,
	|			Partner.Ref,
	|			ServicesForRegistration.Terms
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			1 AS BusinessOperation,
	|			NULL,
	|			Balance.Currency,
	|			Balance.InventoryOwnerAttribute.Organization,
	|			Balance.InventoryOwnerAttribute.GoodsOwner,
	|			Balance.InventoryOwnerAttribute.Counterparty,
	|			Balance.InventoryOwnerAttribute.Terms,
	|			Balance.InventoryOwnerAttribute.Contract,
	|			Balance.InventoryOwnerAttribute.VATTaxation,
	|			SUM(Balance.QuantityToRegisterBalance)
	|		FROM
	|			AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Balance(, ) AS Balance
	|		WHERE
	|			Balance.InventoryOwnerAttribute.GoodsOwner REFS Catalog.Partners
	|			AND Balance.QuantityToRegisterBalance <> 0
	|		
	|		GROUP BY
	|			1,
	|			Balance.Currency,
	|			Balance.InventoryOwnerAttribute.Organization,
	|			Balance.InventoryOwnerAttribute.GoodsOwner,
	|			Balance.InventoryOwnerAttribute.Counterparty,
	|			Balance.InventoryOwnerAttribute.Terms,
	|			Balance.InventoryOwnerAttribute.Contract,
	|			Balance.InventoryOwnerAttribute.VATTaxation) AS NestedQuery
	|	
	|	GROUP BY
	|		NestedQuery.BusinessOperation,
	|		NestedQuery.WriteOffPeriod,
	|		NestedQuery.Currency,
	|		NestedQuery.Organization,
	|		NestedQuery.GoodsOwner,
	|		NestedQuery.Counterparty,
	|		NestedQuery.Terms,
	|		NestedQuery.Contract,
	|		NestedQuery.VATTaxation) AS NestedQuery";
	
	Result = ToDoListServer.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Commissionersreferences
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "ReportsToConsignors";
	UserTaskParent.Presentation  = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
										|ru = 'Отчеты комитентам';
										|en = 'Consignment notifications'; fa = 'Consignment notifications';
										|it = 'report ai committenti';
										|pl = 'Raporty dla komitentów';
										|tr = 'Gönderici raporları'");
	UserTaskParent.HasToDoItems       = Result.ReportsToCommitteesAreRequiredToIssue > 0;
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	
	// ReportsToCommitteesAreRequiredToIssue
	FilterParameters = New Structure;
	FilterParameters.Insert("GoodsOwner", Catalogs.Partners.EmptyRef());
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("CurrentPageName", "PageOfTheOrderForRegistration");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ReportsToCommitteesAreRequiredToIssue";
	ToDoItem.HasToDoItems       = Result.ReportsToCommitteesAreRequiredToIssue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Cần lập bảng kê';
									|ru = 'Требуется оформить';
									|en = 'To register'; fa = 'برای ثبت';
									|it = 'Da formalizzare';
									|pl = 'Należy sporządzić';
									|tr = 'Düzenleme gerekli'");
	ToDoItem.Count     = Result.ReportsToCommitteesAreRequiredToIssue;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ReportsToConsignors";
	
EndProcedure

#EndRegion

Function DefaultFormAssignmentKey() Export
	
	Return "DocumentsReportsToCommittees";
	
EndFunction

#EndRegion

#EndIf