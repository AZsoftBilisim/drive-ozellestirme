#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Retrieves the data necessary for displaying the structure of the production order.
//
// Parameters:
//  Parameters - Structure - data reading parameters. Contains:
//               * Tree - ValueTree - 
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure Generate(Parameters, StorageAddress) Export
	
	Tree = Parameters.Tree;
	Tree.Rows.Clear();
	
	Data = OrderStructureData(Parameters.Orders);
	
	For Each OrderDocument In Parameters.Orders Do
		
		String = Tree.Rows.Add();
		String.OrderDocument = OrderDocument;
		String.LinePresentation = Documents.ProductionOrder2_2.FullOrderPresentation(OrderDocument);
		String.RowType = OrderLineType();
		String.IsExpanded = True;
		
		AddProducts(Data, OrderDocument, String);
		
	EndDo;
	
	ConfigureLineSelection(Tree, Parameters.Filter);
	
	PutToTempStorage(Tree, StorageAddress);
	
EndProcedure

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionOrderStructure2_2);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure AddProducts(Data, Document, Parent)
	
	OrderWithoutSpecification = Parent.Level() = 0
		And Data.OrdersWithoutSpecifications.Find(Document) <> Undefined;
	
	TheStructureOfTheSearch = New Structure("Document", Document);
	Products_1 = Data.Demands.FindRows(TheStructureOfTheSearch);
	
	For Each Product In Products_1 Do
		
		Supply = MeetingNeed(Data, Product);
		
		ThereIsProvisionFromParent = ThereIsProvisionPerformedByParent(Product, Supply, Parent);
		If Product.CountPlan = 0
				Or Product.CountPlan = Product.CountCanceled
				Or ThereIsProvisionFromParent Then // elimination of redundant data in the repair process
			Continue;
		EndIf;
		
		NewRow = Parent.Rows.Add();
		FillPropertyValues(NewRow, Product);
		NewRow.LinePresentation = ProductsClientServer.ProductPresentation(
			Product.ProductsPresentation,
			Product.CharacteristicPresentation);
		
		If Parent.Level() = 0 Then
			NewRow.RowType = LineTypeProducts();
		ElsIf Product.OrderDocument = Parent.OrderDocument Then
			NewRow.RowType = LineTypeSemiFinished();
		Else
			NewRow.RowType = LineTypeSemiFinishedProductOfAnotherOrder();
			NewRow.InformationBar = Documents.ProductionOrder2_2.FullOrderPresentation(Product.OrderDocument);
		EndIf;
		
		EndDateFact = '00010101';
		ProductionLot = Catalogs.ProductionLots.EmptyRef();
		
		For Each String In Supply Do
			
			NewRow.CountReal = NewRow.CountReal + String.CountReal;
			NewRow.QuantityCreated = NewRow.QuantityCreated + String.CountPlan;
			NewRow.EndDatePlan = Max(NewRow.EndDatePlan, String.EndDatePlan);
			EndDateFact = Max(EndDateFact, String.EndDateFact);
			
			If Product.OrderDocument = String.OrderDocument Then
				
				TheStructureOfTheSearch = New Structure("Products, Characteristic, OrderDocument, Stage");
				FillPropertyValues(TheStructureOfTheSearch, String);
				For Each LineTotal_ In Data.Supply.FindRows(TheStructureOfTheSearch) Do
					NewRow.NumberOfPlansTotal = NewRow.NumberOfPlansTotal + LineTotal_.CountPlan;
					NewRow.QuantityFactTotal = NewRow.QuantityFactTotal + LineTotal_.CountReal;
				EndDo;
				
				If OrderWithoutSpecification Then
					AddStagesByNumber(Data, Document, String.Stage, String.ProcessType, NewRow);
				Else
					AddStagesByID(Data, String.ProductionLot, String.ProcessType, NewRow);
				EndIf;
				
			EndIf;
			
			If ProductionLot <> Undefined Then
				If ProductionLot.IsEmpty() Then
					ProductionLot = String.ProductionLot;
				ElsIf ProductionLot <> String.ProductionLot Then
					ProductionLot = Undefined;
				EndIf;
			EndIf;
			
		EndDo;
		
		If (NewRow.CountPlan - NewRow.CountCanceled) <= NewRow.CountReal Then
			NewRow.EndDateFact = EndDateFact;
		EndIf;
		If NewRow.NumberOfPlansTotal = 0 Then
			NewRow.NumberOfPlansTotal = NewRow.CountPlan;
		Else
			NewRow.NumberOfPlansTotal = NewRow.NumberOfPlansTotal + NewRow.CountCanceled;
		EndIf;
		If NewRow.QuantityFactTotal = 0 Then
			NewRow.QuantityFactTotal = NewRow.CountReal;
		EndIf;
		NewRow.QuantityCanceledTotal = NewRow.CountCanceled;
		NewRow.ProductionLot = ProductionLot;
		
		FillInCalculatedDetails(NewRow);
		
		If NewRow.YouCanCreateStages
			And NewRow.BillOfMaterials.IsEmpty()
			And (NewRow.CountPlan - NewRow.CountCanceled) > NewRow.QuantityCreated Then
			
			CreateStagesLine = NewRow.Rows.Insert(0);
			CreateStagesLine.RowType = StringTypeCreateStages();
			CreateStagesLine.OrderDocument = NewRow.OrderDocument;
			
		EndIf;
		
	EndDo;
	
	If OrderWithoutSpecification Then
		
		Rows = Data.Stages.FindRows(New Structure("OrderDocument, Processed", Document, False));
		If Rows.UBound() <> -1 Then
			
			NewRow = Parent.Rows.Add();
			NewRow.OrderDocument = Document;
			NewRow.LinePresentation = NStr("vi = '<Khác>';
											|ru = '<Прочее>';
											|en = '<Other>'; fa = '<Other>';
											|it = '<altro>';
											|pl = '<Other>';
											|tr = '<Diğer>'");
			NewRow.RowType = LineTypeOtherProducts();
			FillInCalculatedDetails(NewRow);
			
			ProcessType = Enums.ProductionProcessTypes.Assembly;
			
			AddStages(Data, Rows, ProcessType, NewRow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AddStagesByNumber(Data, OrderDocument, Stage, ProcessType, Parent)
	
	String = Data.Stages.Find(Stage, "Stage");
	If String = Undefined Then

		Return;
	EndIf;
	
	Rows = CommonClientServer.ValueInArray(String);
	RowsByIndex = New Array;
	
	TheStructureOfTheSearch = New Structure("OrderDocument, NextStageNo", OrderDocument);
	
	For Each String In Rows Do
		
		IndexOf = Data.Stages.IndexOf(String);
		If IndexOf > RowsByIndex.UBound() Then
			RowsByIndex.Insert(IndexOf, String);
		Else
			RowsByIndex.Set(IndexOf, String);
		EndIf;
		
		TheStructureOfTheSearch.NextStageNo = String.StageNumber;
		
		NLines = Data.Stages.FindRows(TheStructureOfTheSearch);
		For Each NString In NLines Do
			Rows.Add(NString);
		EndDo;
		
	EndDo;
	
	Rows.Clear();
	
	For IndexOf = 0 To RowsByIndex.UBound() Do
		
		If RowsByIndex[IndexOf] <> Undefined Then
			
			Rows.Add(RowsByIndex[IndexOf]);
			
		EndIf;
		
	EndDo;
	
	AddStages(Data, Rows, ProcessType, Parent);
	
EndProcedure

Procedure AddStagesByID(Data, ProductionLot, ProcessType, Parent)
	
	Rows = Data.Stages.FindRows(New Structure("ProductionLot", ProductionLot));
	
	If Rows.UBound() <> -1 Then
		
		AddStages(Data, Rows, ProcessType, Parent);
		
	EndIf;
	
EndProcedure

Procedure AddStages(Data, Rows, ProcessType, Parent)
	
	If ProcessType = Enums.ProductionProcessTypes.Disassembly Then
		
		// Direct bypass
		Begin = 0;
		End = Rows.UBound();
		Coef = 1;
		
	Else
		
		// Reverse bypass
		Begin = -Rows.UBound();
		End = 0;
		Coef = -1;
		
	EndIf;
	
	For Cnt = Begin To End Do
		
		Data_Stage = Rows[Cnt*Coef];
		
		NewRow = Parent.Rows.Add();
		
		FillPropertyValues(NewRow, Data_Stage);
		
		NewRow.LinePresentation = Data_Stage.StageName;
		NewRow.RowType = StringTypeStage();
		NewRow.NumberOfPlansTotal = Data_Stage.CountPlan;
		NewRow.QuantityFactTotal = Data_Stage.CountReal;
		NewRow.QuantityCanceledTotal = Data_Stage.CountCanceled;
		
		FillInCalculatedDetails(NewRow);
		
		Data_Stage.Processed = True;
		
		AddProducts(Data, Data_Stage.Stage, NewRow);
		
	EndDo;
	
EndProcedure

Procedure ConfigureLineSelection(Tree, Filter) Export
	
	TheStructureOfTheSearch = New Structure("Filter", True);
	For Each String In Tree.Rows.FindRows(TheStructureOfTheSearch, True) Do
		String.Filter = False;
	EndDo;
	
	QueueSelection = New Array;
	If Not Filter.Products.IsEmpty() Then
		TheStructureOfTheSearch = New Structure("Products", Filter.Products);
		For Each String In Tree.Rows.FindRows(TheStructureOfTheSearch, True) Do
			QueueSelection.Add(String);
		EndDo;
	EndIf;
	If Not Filter.Stage.IsEmpty() Then
		TheStructureOfTheSearch = New Structure("Stage", Filter.Stage);
		For Each String In Tree.Rows.FindRows(TheStructureOfTheSearch, True) Do
			QueueSelection.Add(String);
		EndDo;
	EndIf;
	
	If QueueSelection.UBound() <> -1 Then
		
		TheStructureOfTheSearch = New Structure("IsExpanded", True);
		For Each String In Tree.Rows.FindRows(TheStructureOfTheSearch, True) Do
			String.IsExpanded = False;
		EndDo;
		
		QueueParents = New Array;
		QueueDescendants = New Array;
		
		For Each String In QueueSelection Do
			String.Filter = True;
			If String.Parent <> Undefined Then
				QueueParents.Add(String.Parent);
			EndIf;
			For Each DescendantString In String.Rows Do
				QueueDescendants.Add(DescendantString);
			EndDo;
		EndDo;
		
		While QueueParents.UBound() <> -1 Do
			String = QueueParents[0];
			If Not String.Filter Or Not String.IsExpanded Then
				String.Filter = True;
				String.IsExpanded = True;
				If String.Parent <> Undefined Then
					QueueParents.Add(String.Parent);
				EndIf;
			EndIf;
			QueueParents.Delete(0);
		EndDo;
		
		While QueueDescendants.UBound() <> -1 Do
			String = QueueDescendants[0];
			If Not String.Filter Then
				String.Filter = True;
				For Each DescendantString In String.Rows Do
					QueueDescendants.Add(DescendantString);
				EndDo;
			EndIf;
			QueueDescendants.Delete(0);
		EndDo;
		
	EndIf;
	
EndProcedure

// Data retrieval
Function MeetingNeed(Data, Demand)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products",     Demand.Products);
	TheStructureOfTheSearch.Insert("Characteristic",   Demand.Characteristic);
	TheStructureOfTheSearch.Insert("Purpose",       Demand.Purpose);
	TheStructureOfTheSearch.Insert("ToExpenseAs", Demand.ToExpenseAs);
	
	If Demand.ProcessType = Enums.ProductionProcessTypes.Assembly Then
		
		FieldForSearch      = "Recipient";
		OrderSearchField = "OrderRecipient"; 
		ValueField    = "Sender";
		
	Else
		
		FieldForSearch      = "Sender";
		OrderSearchField = "SenderOrder";
		ValueField    = "Recipient";
		
	EndIf;
	
	TheStructureOfTheSearch.Insert(FieldForSearch, Demand.Document);
	Links = Data.ProductLinks.FindRows(TheStructureOfTheSearch);
	TheStructureOfTheSearch.Delete(FieldForSearch);
	
	TheStructureOfTheSearch.Insert("Stage");
	TheStructureOfTheSearch.Insert("OrderDocument");
	
	Supply = New Array;
	SupplyAccordingToSpecification = New Array;
	QuantityAccordingToBOR = 0;
	
	For IndexOf = 0 To Links.UBound() Do
		
		Link = Links[IndexOf];
		
		// Exclusion of repeated processing of identical strings
		IsDuplicate = False;
		
		For PREVIndex = 1-IndexOf To 0 Do
			
			IsDuplicate = Link[ValueField] = Links[-PREVIndex][ValueField]
				And Link.Purpose = Links[-PREVIndex].Purpose;
				
			If IsDuplicate Then
				Break;
			EndIf;
			
		EndDo;
		
		If IsDuplicate Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch.Stage       = Link[ValueField];
		TheStructureOfTheSearch.OrderDocument      = Link[OrderSearchField];
		TheStructureOfTheSearch.Purpose = Link.Purpose;
		
		FoundRows = Data.Supply.FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			Supply.Add(String);
			
			If Not Demand.BillOfMaterials.IsEmpty()
				And Demand.BillOfMaterials = String.BillOfMaterials Then
				SupplyAccordingToSpecification.Add(String);
				QuantityAccordingToBOR = QuantityAccordingToBOR + String.CountPlan;
			EndIf;
		EndDo;
		
	EndDo;
	
	If SupplyAccordingToSpecification.UBound() <> -1
		And QuantityAccordingToBOR >= (Demand.CountPlan - Demand.CountCanceled) Then
		Return SupplyAccordingToSpecification;
	Else
		Return Supply;
	EndIf;
	
EndFunction

Function ThereIsProvisionPerformedByParent(Demand, Supply, Parent)
	
	If Parent.Level() < 4 Then
		Return False;
	EndIf;
	
	Result = False;
	ParentParty = Parent.Parent.Parent.ProductionLot;
	
	For Each String In Supply Do
		If String.ProductionLot = ParentParty Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Sample data
Function OrderStructureData(Orders)
	
	Query = New Query(QueryTextOrderStructureData());
	
	Query.SetParameter("Orders", Orders);
	Query.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	Query.SetParameter("EmptyStage", Documents.ProductionStage2_2.EmptyRef());
	Query.SetParameter("EmptySpecification", Catalogs.BillsOfMaterials.EmptyRef());
	Query.SetParameter("EmptyOrder", Documents.ProductionOrder2_2.EmptyRef());
	Query.SetParameter("EmptyBatch", Catalogs.ProductionLots.EmptyRef());
	Query.SetParameter("Disassembly", Enums.ProductionProcessTypes.Disassembly);
	Query.SetParameter("Assembly", Enums.ProductionProcessTypes.Assembly);
	Query.SetParameter("WithoutBillsOfMaterials", Enums.ProductionProcessTypes.WithoutBillsOfMaterials);
	Query.SetParameter("ScheduleStatus", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("StatusStageCompleted", Enums.StatusesOfProductionStages2_2.Completed);
	Query.SetParameter("OrderStatusYouCanCreateStages",
		Enums.ProductionOrderStatuses2_2.ToProduce);
	
	ResultsArray = Query.ExecuteBatch();  
	UBound = ResultsArray.UBound();
	
	Result = New Structure;
	
	Result.Insert("ProductLinks", ResultsArray[UBound - 4].Unload());
	Result.Insert("Demands", ResultsArray[UBound - 3].Unload());
	Result.Insert("Supply", ResultsArray[UBound - 2].Unload());
	Result.Insert("Stages", ResultsArray[UBound - 1].Unload());
	Result.Insert("OrdersWithoutSpecifications", ResultsArray[UBound].Unload().UnloadColumn("Ref"));
	
	// Indexing tables
	Result.ProductLinks.Indexes.Add("Products, Characteristic, Purpose, ToExpenseAs, Sender");
	Result.ProductLinks.Indexes.Add("Products, Characteristic, Purpose, ToExpenseAs, Recipient");
	
	Result.Demands.Indexes.Add("Document");
	
	Result.Supply.Indexes.Add("Products, Characteristic, OrderDocument, Stage");
	Result.Supply.Indexes.Add("Products, Characteristic, OrderDocument, Stage, Purpose, ToExpenseAs");
	
	Result.Stages.Indexes.Add("ProductionLot");
	Result.Stages.Indexes.Add("Stage");
	Result.Stages.Indexes.Add("OrderDocument, NextStageNo");
	
	Return Result;
	
EndFunction

Function QueryTextOrderStructureData()
	
	QueryText =
		"SELECT
		|	TabularSection.Ref                              AS OrderDocument,
		|	TabularSection.Products                        AS Products,
		|	TabularSection.Characteristic                      AS Characteristic,
		|	CASE
		|		WHEN ProductionOrder.ProductionProcessType = &WithoutBillsOfMaterials
		|				AND NOT TabularSection.ToExpenseAs
		|			THEN ProductionOrder.AssignmentProducts
		|		ELSE TabularSection.Purpose
		|	END                                              AS Purpose,
		|	CASE
		|		WHEN &EnableAssigmentSupply
		|			THEN  CASE
		|						WHEN ProductionOrder.ProductionProcessType IN (
		|								VALUE(Enum.ProductionProcessTypes.Assembly),
		|								VALUE(Enum.ProductionProcessTypes.Repair))
		|							THEN TabularSection.Purpose
		|						ELSE ProductionOrder.AssignmentProducts
		|					END
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|	END                                              AS AssignmentProducts,
		|	TabularSection.BillOfMaterials                        AS BillOfMaterials,
		|	TabularSection.ToExpenseAs                    AS ToExpenseAs,
		|	TabularSection.ExpenseItem                      AS ExpenseItem,
		|	TabularSection.DimensionOfExpenses                   AS DimensionOfExpenses,
		|	TabularSection.AssetsLiabilitiesDimension            AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN ProductionOrder.ProductionProcessType = &Disassembly
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END                                              AS ProcessType,
		|	ProductionOrder.Status = &OrderStatusYouCanCreateStages AS YouCanCreateStages,
		|	CASE
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			OR TabularSection.ToExpenseAs
		|		THEN CASE
		|				WHEN COUNT(DISTINCT TabularSection.Department) = 1
		|					THEN MIN(TabularSection.Department)
		|				ELSE UNDEFINED
		|			END
		|		ELSE
		|			CASE
		|				WHEN COUNT(DISTINCT TabularSection.Warehouse) = 1
		|					THEN MIN(TabularSection.Warehouse)
		|				ELSE UNDEFINED
		|			END
		|	END                                              AS Warehouse,
		|	TabularSection.Canceled                            AS Canceled,
		|	MIN(TabularSection.LineNumber)                AS LineNumber,
		|	SUM(TabularSection.Count)                   AS Count
		|INTO TTOrdered
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|		LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrder
		|		ON TabularSection.Ref = ProductionOrder.Ref
		|WHERE
		|	TabularSection.Ref IN(&Orders)
		|	AND ProductionOrder.Posted
		|
		|GROUP BY
		|	TabularSection.Products,
		|	TabularSection.BillOfMaterials,
		|	TabularSection.ExpenseItem,
		|	TabularSection.AssetsLiabilitiesDimension,
		|	TabularSection.Ref,
		|	CASE
		|		WHEN ProductionOrder.ProductionProcessType = &Disassembly
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END,
		|	TabularSection.Characteristic,
		|	ProductionOrder.Status = &OrderStatusYouCanCreateStages,
		|	TabularSection.ToExpenseAs,
		|	CASE
		|		WHEN ProductionOrder.ProductionProcessType = &WithoutBillsOfMaterials
		|				AND NOT TabularSection.ToExpenseAs
		|			THEN ProductionOrder.AssignmentProducts
		|		ELSE TabularSection.Purpose
		|	END,
		|	CASE
		|		WHEN &EnableAssigmentSupply
		|			THEN  CASE
		|						WHEN ProductionOrder.ProductionProcessType IN (
		|								VALUE(Enum.ProductionProcessTypes.Assembly),
		|								VALUE(Enum.ProductionProcessTypes.Repair))
		|							THEN TabularSection.Purpose
		|						ELSE ProductionOrder.AssignmentProducts
		|					END
		|		ELSE
		|			VALUE(Catalog.Assignments.EmptyRef)
		|	END,
		|	TabularSection.DimensionOfExpenses,
		|	TabularSection.Canceled
    	|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Document.ReferenceOrder           AS OrderDocument,
		|	Document.Ref                 AS Stage,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END                           AS ProcessType,
		|	Document.ProductionLot     AS ProductionLot,
		|	TabularSection.StageConsumer  AS StageConsumer,
		|
		|	ISNULL(DocumentConsumer.ProductionLot, &EmptyBatch)  AS ProductionBatchConsumer,
		|	ISNULL(DocumentConsumer.ReferenceOrder, &EmptyOrder)  AS OrderConsumer,
		|
		|	TabularSection.Products     AS Products,
		|	TabularSection.Characteristic   AS Characteristic,
		|	TabularSection.Purpose       AS Purpose,
		|	CASE
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabularSection.ToExpenseAs
		|			AND TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Recipient
		|	END                           AS Warehouse,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN TabularSection.BillOfMaterials
		|		ELSE Document.BillOfMaterials
		|	END                           AS BillOfMaterials,
		|	TabularSection.ToExpenseAs AS ToExpenseAs,
		|	TabularSection.RowCode        AS RowCode,
		|	TabularSection.LineNumber      AS LineNumber,
		|	TabularSection.Count       AS Count,
		|	TabularSection.Manufactured      AS Manufactured,
		|	TabularSection.Canceled         AS Canceled
		|INTO TTIssue
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS TabularSection
		|		INNER JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|		LEFT JOIN Document.ProductionStage2_2 AS DocumentConsumer
		|		ON TabularSection.StageConsumer = DocumentConsumer.Ref
		|WHERE
		|	Document.ReferenceOrder IN(&Orders)
		|	AND Document.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	Document.ReferenceOrder,
		|	Document.Ref,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END,
		|	Document.ProductionLot,
		|	TabularSection.StageConsumer,
		|
		|	ISNULL(DocumentConsumer.ProductionLot, &EmptyBatch),
		|	ISNULL(DocumentConsumer.ReferenceOrder, &EmptyOrder),
		|
		|	TabularSection.Products,
		|	TabularSection.Characteristic,
		|	TabularSection.Purpose,
		|	CASE
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabularSection.ToExpenseAs
		|			AND TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Recipient
		|	END,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN TabularSection.BillOfMaterials
		|		ELSE Document.BillOfMaterials
		|	END,
		|	TabularSection.ToExpenseAs,
		|	TabularSection.RowCode,
		|	TabularSection.LineNumber,
		|	TabularSection.Count,
		|	TabularSection.Manufactured,
		|	TabularSection.Canceled
		|FROM
		|	Document.ProductionStage2_2.SideAndIntermediateRelease AS TabularSection
		|		INNER JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|		LEFT JOIN Document.ProductionStage2_2 AS DocumentConsumer
		|		ON TabularSection.StageConsumer = DocumentConsumer.Ref
		|WHERE
		|	Document.ReferenceOrder IN(&Orders)
		|	AND Document.Posted
		|
		|INDEX BY
		|	Stage,
		|	StageConsumer,
		|	ProcessType,
		|	BillOfMaterials
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Document.ReferenceOrder                  AS OrderDocument,
		|	Document.Ref                        AS Stage,
		|	&Assembly                                AS ProcessType,
		|	Document.ProductionLot            AS ProductionLot,
		|	DocumentConsumer.Ref             AS StageConsumer,
		|	DocumentConsumer.ProductionLot AS ProductionBatchConsumer,
		|	DocumentConsumer.ReferenceOrder       AS OrderConsumer,
		|	TabularSection.Products            AS Products,
		|	TabularSection.Characteristic          AS Characteristic,
		|	TabularSection.Purpose              AS Purpose,
		|	CASE
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabularSection.ToExpenseAs
		|			AND TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Recipient
		|	END                                  AS Warehouse,
		|	&EmptySpecification                    AS BillOfMaterials,
		|	TabularSection.ToExpenseAs        AS ToExpenseAs,
		|	TabularSection.RowCode               AS RowCode,
		|	TabularSection.LineNumber             AS LineNumber,
		|	TabularSection.Count              AS Count,
		|	TabularSection.Manufactured             AS Manufactured,
		|	TabularSection.Canceled                AS Canceled
		|INTO TTIssueDifferentOrders
		|FROM
		|	Document.ProductionStage2_2 AS DocumentConsumer
		|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TabularSection
		|		ON DocumentConsumer.Purpose = TabularSection.Purpose
		|		INNER JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	DocumentConsumer.ReferenceOrder IN(&Orders)
		|	AND DocumentConsumer.ReferenceOrder <> Document.ReferenceOrder
		|	AND Document.Posted
		|	AND NOT TabularSection.ProcessByBOM
		|
		|UNION ALL
		|
		|SELECT
		|	Document.ReferenceOrder,
		|	Document.Ref,
		|	&Assembly,
		|	Document.ProductionLot,
		|	DocumentConsumer.Ref,
		|	DocumentConsumer.ProductionLot,
		|	DocumentConsumer.ReferenceOrder,
		|	TabularSection.Products,
		|	TabularSection.Characteristic,
		|	TabularSection.Purpose,
		|	CASE
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabularSection.ToExpenseAs
		|			AND TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Recipient
		|	END,
		|	&EmptySpecification,
		|	TabularSection.ToExpenseAs,
		|	TabularSection.RowCode,
		|	TabularSection.LineNumber,
		|	TabularSection.Count,
		|	TabularSection.Manufactured,
		|	TabularSection.Canceled
		|FROM
		|	Document.ProductionStage2_2 AS DocumentConsumer
		|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS TabularSection
		|		ON DocumentConsumer.Purpose = TabularSection.Purpose
		|		INNER JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	DocumentConsumer.ReferenceOrder IN(&Orders)
		|	AND DocumentConsumer.ReferenceOrder <> Document.ReferenceOrder
		|	AND Document.Posted
		|	AND NOT TabularSection.ProcessByBOM
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionStage2_2.Ref AS Stage
		|INTO TTAllStages
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|WHERE
		|	ProductionStage2_2.ReferenceOrder IN(&Orders)
		|	AND ProductionStage2_2.Posted = TRUE
		|
		|UNION
		|
		|SELECT DISTINCT
		|	TTIssue.Stage
		|FROM
		|	TTIssue AS TTIssue
		|
		|UNION
		|
		|SELECT DISTINCT
		|	TTIssue.StageConsumer
		|FROM
		|	TTIssue AS TTIssue
		|WHERE
		|	TTIssue.StageConsumer <> &EmptyStage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.OrderDocument                AS OrderDocument,
		|	NestedQuery.Stage                 AS Stage,
		|	NestedQuery.ProductionLot   AS ProductionLot,
		|	&Assembly                              AS ProcessType,
		|	NestedQuery.Products         AS Products,
		|	NestedQuery.Characteristic       AS Characteristic,
		|	NestedQuery.Purpose           AS Purpose,
		|	NestedQuery.Warehouse                AS Warehouse,
		|	NestedQuery.BillOfMaterials         AS BillOfMaterials,
		|	NestedQuery.ToExpenseAs     AS ToExpenseAs,
		|	NestedQuery.Canceled             AS Canceled,
		|	MIN(NestedQuery.LineNumber) AS LineNumber,
		|	SUM(NestedQuery.Count)    AS Count
		|INTO TTSoftware
		|FROM
		|	(SELECT
		|		Document.ReferenceOrder         AS OrderDocument,
		|		Document.Ref               AS Stage,
		|		Document.ProductionLot   AS ProductionLot,
		|		TabularSection.Products   AS Products,
		|		TabularSection.Characteristic AS Characteristic,
		|		TabularSection.Purpose     AS Purpose,
		|		CASE WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|			TabularSection.Department
		|		ELSE
		|			TabularSection.Warehouse
		|		END                         AS Warehouse,
		|		TabularSection.BillOfMaterials   AS BillOfMaterials,
		|		FALSE                          AS ToExpenseAs,
		|		TabularSection.Canceled       AS Canceled,
		|		TabularSection.LineNumber    AS LineNumber,
		|		TabularSection.Count     AS Count
		|	FROM
		|		Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TabularSection
		|			LEFT JOIN Document.ProductionStage2_2 AS Document
		|			ON TabularSection.Ref = Document.Ref
		|	WHERE
		|		TabularSection.Ref IN
		|				(SELECT
		|					AllStages.Stage AS Ref
		|				FROM
		|					TTAllStages AS AllStages)
		|		AND Document.Posted
		|		AND TabularSection.Produced
		|		AND NOT (
		|				Document.ProductionProcessType = &Disassembly
		|				AND TabularSection.Products = Document.ProductionLot.MainProductProducts
		|				AND TabularSection.Characteristic = Document.ProductionLot.MainProductCharacteristic
		|			)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTIssue.OrderDocument,
		|		TTIssue.StageConsumer,
		|		TTIssue.ProductionLot,
		|		TTIssue.Products,
		|		TTIssue.Characteristic,
		|		TTIssue.Purpose,
		|		TTIssue.Warehouse,
		|		&EmptySpecification,
		|		TTIssue.ToExpenseAs,
		|		TTIssue.Canceled,
		|		10000,
		|		-TTIssue.Count
		|	FROM
		|		TTIssue AS TTIssue
		|	WHERE
		|		TTIssue.ProcessType = &Assembly
		|		AND TTIssue.StageConsumer <> &EmptyStage
		|		AND TTIssue.ProductionLot = TTIssue.ProductionBatchConsumer) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Characteristic,
		|	NestedQuery.Warehouse,
		|	NestedQuery.Products,
		|	NestedQuery.Purpose,
		|	NestedQuery.Stage,
		|	NestedQuery.ProductionLot,
		|	NestedQuery.BillOfMaterials,
		|	NestedQuery.ToExpenseAs,
		|	NestedQuery.OrderDocument,
		|	NestedQuery.Canceled
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Document.ReferenceOrder,
		|	Document.Ref,
		|	Document.ProductionLot,
		|	&Disassembly,
		|	TabularSection.Products,
		|	TabularSection.Characteristic,
		|	CASE
		|		WHEN TabularSection.Produced 
		|			THEN TabularSection.Purpose
		|		ELSE &EmptyAssignment
		|	END,
		|	TabularSection.Warehouse,
		|	Document.BillOfMaterials,
		|	FALSE,
		|	TabularSection.Canceled,
		|	TabularSection.LineNumber,
		|	TabularSection.Count
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TabularSection
		|		LEFT JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	TabularSection.Ref IN
		|			(SELECT
		|				AllStages.Stage AS Ref
		|			FROM
		|				TTAllStages AS AllStages)
		|	AND Document.Posted
		|	AND Document.ProductionProcessType = &Disassembly
		|	AND TabularSection.Products = Document.ProductionLot.MainProductProducts
		|	AND TabularSection.Characteristic = Document.ProductionLot.MainProductCharacteristic
		|
		|INDEX BY
		|	OrderDocument,
		|	Stage,
		|	ProcessType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Stages.ProductionLot                                      AS ProductionLot,
		|	MIN(CASE
		|			WHEN Stages.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				THEN TRUE
		|			ELSE FALSE
		|		END)                                                    AS StagesCompleted,
		|	MAX(Stages.ActualStageEnd)                     AS EndDateFact,
		|	MAX(ISNULL(Schedule.Ending, DATETIME(1, 1, 1)))      AS EndDatePlan
		|INTO TTTermsOfDisassembly
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON Stages.ReferenceOrder = Schedule.ProductionOrder
		|			AND Stages.Ref = Schedule.Stage
		|			AND (Schedule.ScheduleStatus = &ScheduleStatus)
		|WHERE
		|	Stages.Ref IN
		|			(SELECT
		|				AllStages.Stage AS Ref
		|			FROM
		|				TTAllStages AS AllStages)
		|	AND Stages.Posted
		|	AND Stages.ProductionProcessType = &Disassembly
		|
		|GROUP BY
		|	Stages.ProductionLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	Products_1.Products     AS Products,
		|	Products_1.Characteristic   AS Characteristic,
		|	Products_1.Purpose       AS Purpose,
		|	Products_1.BillOfMaterials     AS BillOfMaterials,
		|	Products_1.ToExpenseAs AS ToExpenseAs,
		|	Products_1.Stage             AS Sender,
		|	Products_1.StageConsumer  AS Recipient,
		|	Products_1.OrderDocument            AS SenderOrder,
		|	Products_1.OrderConsumer AS OrderRecipient
		|FROM
		|	TTIssue AS Products_1
		|WHERE
		|	Products_1.StageConsumer <> &EmptyStage
		|	AND Products_1.ProductionLot <> Products_1.ProductionBatchConsumer
		|	AND NOT Products_1.Canceled
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Products_1.Products     AS Products,
		|	Products_1.Characteristic   AS Characteristic,
		|	Products_1.Purpose       AS Purpose,
		|	Products_1.BillOfMaterials     AS BillOfMaterials,
		|	Products_1.ToExpenseAs AS ToExpenseAs,
		|	Products_1.Stage             AS Sender,
		|	Products_1.StageConsumer  AS Recipient,
		|	Products_1.OrderDocument            AS SenderOrder,
		|	Products_1.OrderConsumer AS OrderRecipient
		|FROM
		|	TTIssueDifferentOrders AS Products_1
		|WHERE
		|	NOT Products_1.Canceled
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	TTOrdered.Products,
		|	TTOrdered.Characteristic,
		|	TTOrdered.Purpose,
		|	TTOrdered.BillOfMaterials,
		|	TTOrdered.ToExpenseAs,
		|	TTIssue.Stage,
		|	TTOrdered.OrderDocument,
		|	TTOrdered.OrderDocument,
		|	TTOrdered.OrderDocument
		|FROM
		|	TTOrdered AS TTOrdered
		|		INNER JOIN TTIssue AS TTIssue
		|		ON TTOrdered.OrderDocument = TTIssue.OrderDocument
		|			AND TTOrdered.Products = TTIssue.Products
		|			AND TTOrdered.Characteristic = TTIssue.Characteristic
		|			AND TTOrdered.Purpose = TTIssue.Purpose
		|			AND TTOrdered.ProcessType = TTIssue.ProcessType
		|WHERE
		|	TTOrdered.ProcessType = &Assembly
		|	AND NOT TTOrdered.Canceled
		|	AND NOT TTIssue.Canceled
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	TTOrdered.Products,
		|	TTOrdered.Characteristic,
		|	TTOrdered.Purpose,
		|	TTOrdered.BillOfMaterials,
		|	TTOrdered.ToExpenseAs,
		|	TTOrdered.OrderDocument,
		|	TTSoftware.Stage,
		|	TTOrdered.OrderDocument,
		|	TTOrdered.OrderDocument
		|FROM
		|	TTOrdered AS TTOrdered
		|		INNER JOIN TTSoftware AS TTSoftware
		|		ON TTOrdered.OrderDocument = TTSoftware.OrderDocument
		|			AND TTOrdered.Products = TTSoftware.Products
		|			AND TTOrdered.Characteristic = TTSoftware.Characteristic
		|			AND TTOrdered.ProcessType = TTSoftware.ProcessType
		|		LEFT JOIN TTIssue AS TTIssue
		|		ON (TTSoftware.Products = TTIssue.Products)
		|			AND (TTSoftware.Characteristic = TTIssue.Characteristic)
		|			AND (TTSoftware.Stage = TTIssue.StageConsumer)
		|WHERE
		|	TTOrdered.ProcessType = &Disassembly
		|	AND NOT TTOrdered.Canceled
		|	AND NOT TTSoftware.Canceled
		|	AND TTIssue.Products IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Demands.OrderDocument                         AS OrderDocument,
		|	Demands.Document                      AS Document,
		|	Demands.Products                  AS Products,
		|	Demands.Characteristic                AS Characteristic,
		|	Demands.Purpose                    AS Purpose,
		|	Demands.AssignmentProducts           AS AssignmentProducts,
		|	Demands.BillOfMaterials                  AS BillOfMaterials,
		|	Demands.ToExpenseAs              AS ToExpenseAs,
		|	Demands.ExpenseItem                AS ExpenseItem,
		|	Demands.DimensionOfExpenses             AS DimensionOfExpenses,
		|	Demands.AssetsLiabilitiesDimension      AS AssetsLiabilitiesDimension,
		|	Demands.Products.Presentation    AS ProductsPresentation,
		|	Demands.Products.UnitOfMeasure AS UnitOfMeasure,
		|	Demands.Characteristic.Presentation  AS CharacteristicPresentation,
		|	Demands.ProcessType                   AS ProcessType,
		|	Demands.ProductionLot            AS ProductionLot,
		|	Demands.YouCanCreateStages           AS YouCanCreateStages,
		|	CASE
		|		WHEN COUNT(DISTINCT Demands.Warehouse) = 1
		|			THEN MIN(Demands.Warehouse)
		|		ELSE UNDEFINED
		|	END                                     AS Warehouse,
		|	MIN(Demands.LineNumber)          AS LineNumber,
		|	SUM(Demands.CountPlan)         AS CountPlan,
		|	SUM(Demands.CountCanceled)     AS CountCanceled
		|FROM
		|	(SELECT
		|		TTOrdered.OrderDocument                    AS OrderDocument,
		|		TTOrdered.OrderDocument                    AS Document,
		|		TTOrdered.Products             AS Products,
		|		TTOrdered.Characteristic           AS Characteristic,
		|		TTOrdered.Purpose               AS Purpose,
		|		TTOrdered.AssignmentProducts      AS AssignmentProducts,
		|		TTOrdered.Warehouse                    AS Warehouse,
		|		TTOrdered.BillOfMaterials             AS BillOfMaterials,
		|		TTOrdered.ToExpenseAs         AS ToExpenseAs,
		|		TTOrdered.ExpenseItem           AS ExpenseItem,
		|		TTOrdered.DimensionOfExpenses        AS DimensionOfExpenses,
		|		TTOrdered.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|		TTOrdered.ProcessType              AS ProcessType,
		|		TTOrdered.LineNumber              AS LineNumber,
		|		TTOrdered.Count               AS CountPlan,
		|		CASE
		|			WHEN TTOrdered.Canceled
		|				THEN TTOrdered.Count
		|			ELSE 0
		|		END                               AS CountCanceled,
		|		UNDEFINED                        AS ProductionLot,
		|		TTOrdered.YouCanCreateStages      AS YouCanCreateStages
		|	FROM
		|		TTOrdered AS TTOrdered
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTSoftware.OrderDocument,
		|		TTSoftware.Stage,
		|		TTSoftware.Products,
		|		TTSoftware.Characteristic,
		|		TTSoftware.Purpose,
		|		CASE
		|			WHEN &EnableAssigmentSupply
		|				THEN TTSoftware.Stage.AssignmentProducts
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		TTSoftware.Warehouse,
		|		TTSoftware.BillOfMaterials,
		|		TTSoftware.ToExpenseAs,
		|		UNDEFINED,
		|		UNDEFINED,
		|		UNDEFINED,
		|		TTSoftware.ProcessType,
		|		TTSoftware.LineNumber,
		|		TTSoftware.Count,
		|		CASE
		|			WHEN TTSoftware.Canceled
		|				THEN TTSoftware.Count
		|			ELSE 0
		|		END,
		|		TTSoftware.Stage.ProductionLot,
		|		ProductionOrder.Status = &OrderStatusYouCanCreateStages
		|	FROM
		|		TTSoftware AS TTSoftware
		|			LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrder
		|			ON TTSoftware.OrderDocument = ProductionOrder.Ref
		|	WHERE
		|		TTSoftware.ProcessType = &Assembly
		|	
		|	UNION ALL
		|
		|	SELECT
		|		TTIssueDifferentOrders.OrderDocument,
		|		TTIssueDifferentOrders.StageConsumer,
		|		TTIssueDifferentOrders.Products,
		|		TTIssueDifferentOrders.Characteristic,
		|		TTIssueDifferentOrders.Purpose,
		|		CASE
		|			WHEN &EnableAssigmentSupply
		|				THEN TTIssueDifferentOrders.StageConsumer.AssignmentProducts
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		TTIssueDifferentOrders.Warehouse,
		|		TTIssueDifferentOrders.BillOfMaterials,
		|		TTIssueDifferentOrders.ToExpenseAs,
		|		UNDEFINED,
		|		UNDEFINED,
		|		UNDEFINED,
		|		TTIssueDifferentOrders.ProcessType,
		|		0,
		|		TTIssueDifferentOrders.Count,
		|		CASE
		|			WHEN TTIssueDifferentOrders.Canceled
		|				THEN TTIssueDifferentOrders.Count
		|			ELSE 0
		|		END,
		|		TTIssueDifferentOrders.StageConsumer.ProductionLot,
		|		ProductionOrder.Status = &OrderStatusYouCanCreateStages
		|	FROM
		|		TTIssueDifferentOrders AS TTIssueDifferentOrders
		|			LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrder
		|			ON TTIssueDifferentOrders.OrderConsumer = ProductionOrder.Ref
		|
		|	UNION ALL
		|	
		|	SELECT
		|		TTIssue.OrderDocument,
		|		TTIssue.Stage,
		|		TTIssue.Products,
		|		TTIssue.Characteristic,
		|		TTIssue.Purpose,
		|		CASE
		|			WHEN &EnableAssigmentSupply
		|				THEN ProductionStage.AssignmentProducts
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		TTIssue.Warehouse,
		|		TTIssue.BillOfMaterials,
		|		TTIssue.ToExpenseAs,
		|		UNDEFINED,
		|		UNDEFINED,
		|		UNDEFINED,
		|		TTIssue.ProcessType,
		|		TTIssue.LineNumber,
		|		TTIssue.Count,
		|		CASE
		|			WHEN TTIssue.Canceled
		|				THEN TTIssue.Count
		|			ELSE 0
		|		END,
		|		TTIssue.ProductionLot,
		|		ProductionOrder.Status = &OrderStatusYouCanCreateStages
		|	FROM
		|		TTIssue AS TTIssue
		|			LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrder
		|			ON TTIssue.OrderDocument = ProductionOrder.Ref
		|			LEFT JOIN Document.ProductionStage2_2 AS ProductionStage
		|			ON TTIssue.Stage = ProductionStage.Ref
		|	WHERE
		|		TTIssue.ProcessType = &Disassembly) AS Demands
		|
		|GROUP BY
		|	Demands.ProcessType,
		|	Demands.BillOfMaterials,
		|	Demands.Products,
		|	Demands.Document,
		|	Demands.OrderDocument,
		|	Demands.Characteristic,
		|	Demands.Purpose,
		|	Demands.AssignmentProducts,
		|	Demands.ToExpenseAs,
		|	Demands.ExpenseItem,
		|	Demands.DimensionOfExpenses,
		|	Demands.AssetsLiabilitiesDimension,
		|	Demands.Products.Presentation,
		|	Demands.Products.UnitOfMeasure,
		|	Demands.Characteristic.Presentation,
		|	Demands.ProductionLot,
		|	Demands.YouCanCreateStages
		|
		|ORDER BY
		|	Document,
		|	LineNumber,
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Supply.OrderDocument                       AS OrderDocument,
		|	Supply.Stage                        AS Stage,
		|	Supply.Products                AS Products,
		|	Supply.Characteristic              AS Characteristic,
		|	Supply.Purpose                  AS Purpose,
		|	Supply.ToExpenseAs            AS ToExpenseAs,
		|	Supply.EndDatePlan           AS EndDatePlan,
		|	MAX(Supply.EndDateFact) AS EndDateFact,
		|	Supply.ProcessType                 AS ProcessType,
		|	Supply.ProductionLot AS ProductionLot,
		|	SUM(Supply.CountPlan)       AS CountPlan,
		|	SUM(Supply.CountReal)       AS CountReal,
		|	MAX(Supply.BillOfMaterials)      AS BillOfMaterials
		|FROM
		|	(SELECT
		|		TTIssue.OrderDocument AS OrderDocument,
		|		TTIssue.Stage AS Stage,
		|		TTIssue.Products AS Products,
		|		TTIssue.Characteristic AS Characteristic,
		|		TTIssue.Purpose AS Purpose,
		|		TTIssue.ToExpenseAs AS ToExpenseAs,
		|		TTIssue.Count AS CountPlan,
		|		CASE
		|			WHEN TTIssue.Manufactured
		|				THEN TTIssue.Count
		|			ELSE 0
		|		END AS CountReal,
		|		ISNULL(ScheduleOfProductionStages2_2.Ending, DATETIME(1, 1, 1)) AS EndDatePlan,
		|		ProductionStage2_2.ActualStageEnd AS EndDateFact,
		|		TTIssue.ProcessType AS ProcessType,
		|		TTIssue.ProductionLot AS ProductionLot,
		|		TTIssue.BillOfMaterials AS BillOfMaterials
		|	FROM
		|		TTIssue AS TTIssue
		|			LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|			ON TTIssue.Stage = ProductionStage2_2.Ref
		|			LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|			ON (ProductionStage2_2.ReferenceOrder = ScheduleOfProductionStages2_2.ProductionOrder)
		|				AND TTIssue.Stage = ScheduleOfProductionStages2_2.Stage
		|				AND (ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus)
		|	WHERE
		|		TTIssue.ProcessType = &Assembly
		|		AND NOT TTIssue.Canceled
		|	
		|	UNION ALL
		|
		|	SELECT
		|		TTIssueDifferentOrders.OrderConsumer,
		|		TTIssueDifferentOrders.Stage,
		|		TTIssueDifferentOrders.Products,
		|		TTIssueDifferentOrders.Characteristic,
		|		TTIssueDifferentOrders.Purpose,
		|		TTIssueDifferentOrders.ToExpenseAs,
		|		TTIssueDifferentOrders.Count,
		|		CASE
		|			WHEN TTIssueDifferentOrders.Manufactured
		|				THEN TTIssueDifferentOrders.Count
		|			ELSE 0
		|		END,
		|		ISNULL(ScheduleOfProductionStages2_2.Ending, DATETIME(1, 1, 1)),
		|		ProductionStage2_2.ActualStageEnd,
		|		TTIssueDifferentOrders.ProcessType,
		|		TTIssueDifferentOrders.ProductionLot,
		|		TTIssueDifferentOrders.BillOfMaterials
		|	FROM
		|		TTIssueDifferentOrders AS TTIssueDifferentOrders
		|			LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|			ON TTIssueDifferentOrders.Stage = ProductionStage2_2.Ref
		|			LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|			ON (ProductionStage2_2.ReferenceOrder = ScheduleOfProductionStages2_2.ProductionOrder)
		|				AND TTIssueDifferentOrders.Stage = ScheduleOfProductionStages2_2.Stage
		|				AND (ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus)
		|	WHERE
		|		NOT TTIssueDifferentOrders.Canceled
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTIssue.OrderDocument,
		|		TTIssue.Stage,
		|		TTIssue.Products,
		|		TTIssue.Characteristic,
		|		TTIssue.Purpose,
		|		TTIssue.ToExpenseAs,
		|		0,
		|		ReleasedByProcessor.ToRegisterExpense,
		|		ISNULL(ScheduleOfProductionStages2_2.Ending, DATETIME(1, 1, 1)),
		|		ReleasedByProcessor.Period,
		|		TTIssue.ProcessType,
		|		TTIssue.ProductionLot,
		|		TTIssue.BillOfMaterials
		|	FROM
		|		TTIssue AS TTIssue
		|		
		|		LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|		ON TTIssue.Stage = ProductionStage2_2.Ref
		|		
		|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|		ON (ProductionStage2_2.ReferenceOrder = ScheduleOfProductionStages2_2.ProductionOrder)
		|		AND TTIssue.Stage = ScheduleOfProductionStages2_2.Stage
		|		AND (ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus)
		|		
		|		INNER JOIN AccumulationRegister.PurchaseOrders.Turnovers(,,
		|									Recorder,
		|									VALUETYPE(PurchaseOrder) IN(
		|										TYPE(Document.SubcontractOrder2_5))
		|			) AS ReleasedByProcessor
		|		ON ProductionStage2_2.SubcontractOrder = ReleasedByProcessor.PurchaseOrder
		|		AND TTIssue.RowCode = ReleasedByProcessor.RowCode
		|
		|	WHERE
		|		TTIssue.ProcessType = &Assembly
		|		AND NOT TTIssue.Canceled
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTSoftware.OrderDocument,
		|		TTSoftware.Stage,
		|		TTSoftware.Products,
		|		TTSoftware.Characteristic,
		|		TTSoftware.Purpose,
		|		TTSoftware.ToExpenseAs,
		|		TTSoftware.Count,
		|		CASE
		|			WHEN TTTermsOfDisassembly.StagesCompleted
		|				THEN TTSoftware.Count
		|			ELSE 0
		|		END,
		|		TTTermsOfDisassembly.EndDatePlan,
		|		CASE
		|			WHEN TTTermsOfDisassembly.StagesCompleted
		|				THEN TTTermsOfDisassembly.EndDateFact
		|			ELSE DATETIME(1, 1, 1)
		|		END,
		|		TTSoftware.ProcessType,
		|		ProductionStage2_2.ProductionLot,
		|		TTSoftware.BillOfMaterials
		|	FROM
		|		TTSoftware AS TTSoftware
		|			LEFT JOIN Document.ProductionStage2_2 AS ProductionStage2_2
		|			ON TTSoftware.Stage = ProductionStage2_2.Ref
		|			LEFT JOIN TTTermsOfDisassembly AS TTTermsOfDisassembly
		|			ON (ProductionStage2_2.ProductionLot = TTTermsOfDisassembly.ProductionLot)
		|	WHERE
		|		TTSoftware.ProcessType = &Disassembly
		|		AND NOT TTSoftware.Canceled
		|	) AS Supply
		|
		|GROUP BY
		|	Supply.Stage,
		|	Supply.Purpose,
		|	Supply.Products,
		|	Supply.EndDatePlan,
		|	Supply.Characteristic,
		|	Supply.ProcessType,
		|	Supply.OrderDocument,
		|	Supply.ToExpenseAs,
		|	Supply.ProductionLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Stages.ReferenceOrder                 AS OrderDocument,
		|	Stages.Ref                       AS Stage,
		|	Stages.ProductionLot           AS ProductionLot,
		|	Stages.StageName            AS StageName,
		|	Stages.Department                AS Department,
		|	CASE
		|		WHEN Stages.Status = &StatusStageCompleted
		|			THEN TRUE
		|		ELSE FALSE
		|	END                              AS Completed,
		|	CASE
		|		WHEN Stages.PackagePlan = Stages.PackageActualData
		|				AND Stages.PackagePlan = Stages.PackageCanceled
		|			THEN Stages.NumberOfPackagesPlan
		|		ELSE Stages.NumberOfPackagesPlan * ISNULL(&PackagingFactorPlan, 1)
		|	END                              AS CountPlan,
		|	CASE
		|		WHEN Stages.PackagePlan = Stages.PackageActualData
		|				AND Stages.PackagePlan = Stages.PackageCanceled
		|			THEN Stages.NumberOfPackagesReal
		|		ELSE Stages.NumberOfPackagesReal * ISNULL(&PackagingFactorFact, 1)
		|	END                              AS CountReal,
		|	CASE
		|		WHEN Stages.PackagePlan = Stages.PackageActualData
		|				AND Stages.PackagePlan = Stages.PackageCanceled
		|			THEN Stages.NumberOfPackagesCanceled
		|		ELSE Stages.NumberOfPackagesCanceled * ISNULL(&PackagingFactorCanceled, 1)
		|	END                              AS CountCanceled,
		|	CASE
		|		WHEN Stages.PackagePlan = Stages.PackageActualData
		|				AND Stages.PackagePlan = Stages.PackageCanceled
		|				AND Stages.PackagePlan <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN Stages.PackagePlan
		|		ELSE Stages.ProductionLot.MainProductProducts.UnitOfMeasure
		|	END                              AS UnitOfMeasure,
		|	Stages.StageNumber                   AS StageNumber,
		|	Stages.NextStageNo         AS NextStageNo,
		|	Schedule.Ending                   AS EndDatePlan,
		|	Stages.ActualStageEnd    AS EndDateFact,
		|	Stages.ProductionProcessType AS ProcessType,
		|	Stages.ReferenceOrder.ProductionProcessType = &WithoutBillsOfMaterials AS StageProductionWithoutSpecification,
		|	Stages.ProductionByThirdParty        AS StageProductionOnTheSide,
		|	FALSE AS Processed
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON Stages.ReferenceOrder = Schedule.ProductionOrder
		|			AND Stages.Ref = Schedule.Stage
		|			AND (Schedule.ScheduleStatus = &ScheduleStatus)
		|WHERE
		|	Stages.ReferenceOrder IN(&Orders)
		|	AND Stages.Posted
		|
		|ORDER BY
		|	ProductionLot,
		|	StageNumber,
		|	NextStageNo,
		|	Stages.Ref
		|	
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|// OrdersWithoutSpecifications
		|SELECT
		|	Orders.Ref
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	Orders.Ref IN (&Orders)
		|	AND Orders.Posted
		|	AND Orders.ProductionProcessType = &WithoutBillsOfMaterials";
	
	QueryText = StrReplace(QueryText,
		"&EnableAssigmentSupply",
		Documents.ProductionOrder2_2.RequestTextFieldIsSeparate("ProductionOrder"));
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorPlan",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackagePlan",
			"Stages.ProductionLot.MainProductProducts"));
			
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorFact",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackageActualData",
			"Stages.ProductionLot.MainProductProducts"));
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorCanceled",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Stages.PackageCanceled",
			"Stages.ProductionLot.MainProductProducts"));
	
	Return QueryText;
	
EndFunction

// Constants
Function OrderLineType()
	
	Return 3;
	
EndFunction

Function LineTypeProducts()
	
	Return 1;
	
EndFunction

Function LineTypeSemiFinished()
	
	Return 2;
	
EndFunction

Function StringTypeStage()
	
	Return 4;
	
EndFunction

Function LineTypeSemiFinishedProductOfAnotherOrder()
	
	Return 5;
	
EndFunction

Function LineTypeOtherProducts()
	
	Return 7;
	
EndFunction

Function StringTypeCreateStages()
	
	Return 6;
	
EndFunction

Procedure FillInCalculatedDetails(TreeRow)
	
	TreeRow.PictureNumber = PictureNumber(TreeRow.RowType, TreeRow.ProcessType);
	
	If TreeRow.RowType = StringTypeStage()
		Or TreeRow.RowType = LineTypeSemiFinished()
		Or TreeRow.RowType = LineTypeSemiFinishedProductOfAnotherOrder() Then
		
		TreeRow.ExecutedPerformed = ?(TreeRow.RowType = StringTypeStage(),
			TreeRow.Completed,
			(TreeRow.CountPlan - TreeRow.CountCanceled) <= TreeRow.CountReal);
		
		TreeRow.ExecutedPerformedParent = TreeRow.Parent.ExecutedPerformed;
		
	Else
		
		TreeRow.ExecutedPerformed = False;
		
	EndIf;
	
	If Not (TreeRow.RowType = StringTypeStage()
				And (TreeRow.StageProductionOnTheSide Or TreeRow.StageProductionWithoutSpecification)) Then
		
		TreeRow.TheAmountOfTheShortfall = TreeRow.CountPlan
			- TreeRow.CountCanceled
			- TreeRow.CountReal;
		
		TreeRow.QuantityDeficitTotal = TreeRow.NumberOfPlansTotal
			- TreeRow.QuantityCanceledTotal
			- TreeRow.QuantityFactTotal;
		
	EndIf;
	
EndProcedure

Function PictureNumber(RowType, ProcessType)
	
	If RowType = LineTypeSemiFinished()
		Or RowType = LineTypeSemiFinishedProductOfAnotherOrder() Then
		
		If ProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly") Then
			
			Result = 6;
			
		Else
			
			Result = 2;
			
		EndIf;
		
	ElsIf RowType = StringTypeStage() Then
		
		Result = 1;
		
	Else
		
		Result = 0;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
