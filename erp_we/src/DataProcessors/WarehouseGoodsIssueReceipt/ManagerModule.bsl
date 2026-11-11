#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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

#Region Private

#Region Print

// Fills in the list of print commands.
//
//	Parameters:
//		PrintCommands - See PrintManagement.CreatePrintCommandsCollection.
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// 
// Parameters:
// 	ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "DataProcessor.WarehouseGoodsIssueReceipt.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.WriteOffOfGoodsShortages))
		And (AccessRight("Insert", Metadata.Documents.WriteOffOfGoodsShortages)
			Or AccessRight("Insert", Metadata.Documents.InventorySurplusRecognition)
			Or AccessRight("Insert", Metadata.Documents.GoodsMisgrading)
			Or AccessRight("Insert", Metadata.Documents.GoodsDamage))
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages);
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(1) AS GroundsForRegistrationOfWarehouseActs
	|FROM
	|	(SELECT DISTINCT
	|		GoodsForRegistrationOfSurplusesAndShortagesBalance.Products AS Products,
	|		GoodsForRegistrationOfSurplusesAndShortagesBalance.Characteristic AS Characteristic
	|	FROM
	|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(, ) AS GoodsForRegistrationOfSurplusesAndShortagesBalance
	|	WHERE
	|		GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance <> 0) AS RequirementsForRegistration_1";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Formalizationcladic acts
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "WarehouseActRegistration";
	UserTaskParent.Presentation  = NStr("vi = 'Lập biên bản kho bãi';
										|ru = 'Оформление складских актов';
										|en = 'Inventory adjustments'; fa = 'تعدیل‌های موجودی';
										|it = 'Formalizzazione degli atti di magazzino';
										|pl = 'Rejestracja akt magazynowych';
										|tr = 'Stok düzeltmelerinin düzenlenmesi'");
	UserTaskParent.HasToDoItems       = Result.GroundsForRegistrationOfWarehouseActs > 0;
	UserTaskParent.Owner       = Metadata.Subsystems.Warehouse;
	
	// GroundsForRegistrationOfWarehouseActs
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPageName", "FoundationPage");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "GroundsForRegistrationOfWarehouseActs";
	ToDoItem.HasToDoItems       = Result.GroundsForRegistrationOfWarehouseActs > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hàng hóa cần lập chứng từ';
									|ru = 'Товары к оформлению';
									|en = 'Goods for registration'; fa = 'کالاها برای ثبت';
									|it = 'Merci da formalizzare';
									|pl = 'Towary do rejestracji';
									|tr = 'Ürünlerin düzenlenmesi'");
	ToDoItem.Count     = Result.GroundsForRegistrationOfWarehouseActs;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "WarehouseActRegistration";
	
EndProcedure

#EndRegion

#Region CreatingHyperlinkInPurchaseLog 

Function QueryTextToRegister() Export
	
	Return
	"SELECT ALLOWED TOP 1
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Products,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Characteristic,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Series,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Purpose
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(
	|			,
	|			Warehouse = &Warehouse
	|				OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)) AS GoodsForRegistrationOfSurplusesAndShortagesBalance
	|WHERE
	|	NOT GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance = 0";
	
EndFunction

Function CreateHyperlinkToDesign(Parameters) Export
	
	Warehouse = Parameters.Warehouse;
	If ValueIsFilled(Warehouse)
			And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Parameters.Warehouse)
		Or Not WarehousesServer.ThereAreAllowedWarehousesOrderWhenReflectingSurplusShortages()
		Or Not AccessManagement.HasRole("ReadGoodsForRegistrationOfSurplusesAndShortages") Then
		
		Return Undefined;
		
	EndIf;
	
	Query = New Query(QueryTextToRegister());
	Query.SetParameter("Warehouse",Parameters.Warehouse);
	HyperlinkText = NStr("vi = 'Biên bản';
						|ru = 'Акты';
						|en = 'Reports'; fa = 'گزارش‌ها';
						|it = 'Atti';
						|pl = 'Akty';
						|tr = 'Tutanaklar'");
	RowsArray = New Array;
	If Query.Execute().IsEmpty() Then
		
		RowsArray.Add(New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			"Report.UnregisteredSurplusesAndShortagesOfGoods.Form"));
		
	Else
		
		RowsArray.Add(New FormattedString(HyperlinkText,,,,
			"Report.UnregisteredSurplusesAndShortagesOfGoods.Form"));
		If AccessManagement.HasRole("AddEditWarehouseGoodsIssueReceipt") Then
			RowsArray.Add(",");
			RowsArray.Add(" ");
			RowsArray.Add(New FormattedString(NStr("vi = 'tạo';
													|ru = 'оформить';
													|en = 'register'; fa = 'register';
													|it = 'preparare';
													|pl = 'register';
													|tr = 'düzenle'"),,,,
				"DataProcessor.WarehouseGoodsIssueReceiptWizard.Form"));
		EndIf;
		
	EndIf;
	
	Return New FormattedString(RowsArray);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
