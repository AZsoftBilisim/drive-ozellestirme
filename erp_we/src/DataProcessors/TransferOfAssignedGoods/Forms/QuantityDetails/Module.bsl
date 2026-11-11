
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// Completion.
	Totals = FillInMovementTable(Parameters.DetailsData);
	TheInscriptionIsAvailable = Totals.QuantityIsAvailable;
	TheInscriptionNeed = Totals.QuantityNeed;
	
	// Setting up the form.
	Query = New Query();
	Query.Text =
		"SELECT
		|	CAST(&Products AS Catalog.Products).Description AS Products,
		|	CAST(&Characteristic AS Catalog.ItemsCharacteristics).Description AS Characteristic,
		|	CAST(&Purpose AS Catalog.Assignments).Description AS Purpose,
		|	CAST(&Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure";
	Query.SetParameter("Products",   Parameters.Products);
	Query.SetParameter("Characteristic", Parameters.Characteristic);
	Query.SetParameter("Purpose",     Parameters.Purpose);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	InscriptionCharacteristics = ?(ValueIsFilled(Parameters.Characteristic), ", Selection.Characteristic", "");
	Items.DecorationProduct.Title = StrTemplate(Items.DecorationProduct.Title,
		Selection.Products, InscriptionCharacteristics, Selection.Purpose, Selection.UnitOfMeasure);
	
	If Parameters.Mode = "StockAllocation" Then
		
		If Constants.OptionOfOrderingDemandsByOrdersForSupply.Get()
				= Enums.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate Then
			
			Items.GoodsDetailsDemandDate.Visible = False;
			Items.GoodsDetailsPeriod.Visible = False;
			
		EndIf;
		
		Items.TheInscriptionNeed.Visible = False;
		Items.GoodsDetailsAvailable.Visible = False;
		Title = StrTemplate(NStr("vi = 'Lịch trình Điều chuyển hàng hóa từ kho: %1';
								|ru = 'График перемещения товаров со склада: %1';
								|en = 'Schedule of goods transfer from the warehouse: %1'; fa = 'Schedule of goods transfer from the warehouse: %1';
								|it = 'Piano di trasferimento merci dal magazzino: %1';
								|pl = 'Harmonogram przemieszczenia towarów z magazynu: %1';
								|tr = 'Ürünlerin ambardan transferi için program: %1'"), Parameters.SourceWarehouse);
		Items.GoodsDetailsWarehouse.Title = NStr("vi = 'Kho nhận';
												|ru = 'Склад-получатель';
												|en = 'Destination warehouse'; fa = 'انبار مقصد';
												|it = 'Magazzino-destinatario';
												|pl = 'Destination warehouse';
												|tr = 'Hedef ambar'");
		
	ElsIf Parameters.Mode = "Demand_fulfillment" Then
		
		Items.TheInscriptionIsAvailable.Visible = False;
		Items.GoodsDetailsDemandDate.Visible = False;
		Items.GoodsDetailsPeriod.Visible = False;
		Items.GoodsDetailsDemand.Visible = False;
		Title = StrTemplate(NStr("vi = 'Lịch trình Điều chuyển hàng hóa đến kho: %1';
								|ru = 'График перемещения товаров на склад: %1';
								|en = 'Schedule of goods transfer to the warehouse: %1'; fa = 'Schedule of goods transfer to the warehouse: %1';
								|it = 'Piano di trasferimento merci al magazzino: %1';
								|pl = 'Harmonogram przemieszczenia towarów do magazynu: %1';
								|tr = 'Ürünlerin ambara transferi için program: %1'"), Parameters.DestinationWarehouse);
		Items.GoodsDetailsWarehouse.Title = NStr("vi = 'Kho gửi';
												|ru = 'Склад-отправитель';
												|en = 'Origin warehouse'; fa = 'انبار مبدأ';
												|it = 'Magazzino-mittente';
												|pl = 'Origin warehouse';
												|tr = 'Çıkış ambarı'");
		
	EndIf;
	
	// Subscriptions of standard subsystems.
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region HandlersOfTabularPartOfProductDecryption

&AtClient
Procedure GoodsDetailsMarkOnChange(Item)
	
	CurrentData = Items.GoodsDetails.CurrentData;
	CurrentData.ToMoveAlongRow = ?(CurrentData.Mark, CurrentData.ForTransfer, 0);
	
EndProcedure

&AtClient
Procedure GoodsDetailsForTransferOnChange(Item)
	
	CurrentData = Items.GoodsDetails.CurrentData;
	CurrentData.ToMoveAlongRow = ?(CurrentData.Mark, CurrentData.ForTransfer, 0);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	CloseParameter = New Structure();
	
	ForTransfer = Object.GoodsDetails.Total("ToMoveAlongRow");
	CloseParameter.Insert("ForTransfer", ForTransfer);
	DetailsData = PutGoodsInTemporaryStorageDecryption();
	CloseParameter.Insert("DetailsData", DetailsData);
	Close(CloseParameter);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FillInMovementTable(DetailsData)
	
	ResultStructure1 = DataProcessors.TransferOfAssignedGoods.DetailedRecords(Parameters);
	
	QuantityIsAvailable = ResultStructure1.QuantityIsAvailable;
	QuantityNeed = ResultStructure1.QuantityNeed;
	
	Totals = New Structure("QuantityIsAvailable, QuantityNeed", QuantityIsAvailable, QuantityNeed);
	
	Object.GoodsDetails.Load(ResultStructure1.DetailedRecords);
	
	// Calculation of the quantity to be moved
	If IsTempStorageURL(DetailsData) Then
		
		FillInAmountToBeMovedBasedOnDecryptionData(DetailsData);
		
	Else
		
		If Parameters.Mode = "StockAllocation" Then
			
			For Each TableRow In Object.GoodsDetails Do
				
				If TableRow.ThisIsOutsideThePeriodLimit Or QuantityIsAvailable <= 0 Then
					Break;
				EndIf;
				
				TableRow.ForTransfer = Min(TableRow.Demand, QuantityIsAvailable);
				TableRow.ToMoveAlongRow = TableRow.ForTransfer;
				
				If TableRow.ForTransfer > 0 Then
					TableRow.Mark = True;
				EndIf;
				
				QuantityIsAvailable = QuantityIsAvailable - TableRow.ForTransfer;
				
			EndDo;
		
		ElsIf Parameters.Mode = "Demand_fulfillment" Then
			
			For Each TableRow In Object.GoodsDetails Do
				
				If TableRow.ThisIsOutsideThePeriodLimit Or QuantityNeed <= 0 Then
					Break;
				EndIf;
				
				TableRow.ForTransfer = Min(TableRow.Available, QuantityNeed);
				TableRow.ToMoveAlongRow = TableRow.ForTransfer;
				
				If TableRow.ForTransfer > 0 Then
					TableRow.Mark = True;
				EndIf;
				
				QuantityNeed = QuantityNeed - TableRow.ForTransfer;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Totals;
	
EndFunction

&AtServer
Procedure FillInAmountToBeMovedBasedOnDecryptionData(DetailsData)
	
	DecryptionDataTable = GetFromTempStorage(DetailsData);
	
	For Counter = 1 To DecryptionDataTable.Count() Do
		
		DecryptionString = DecryptionDataTable[Counter - 1];
		
		FoundRow = Undefined;
		For Each TableRow In Object.GoodsDetails Do
			
			If TableRow.PriorityOfOrderingProps < DecryptionString.PriorityOfOrderingProps
					Or TableRow.PriorityOfOrderingProps = DecryptionString.PriorityOfOrderingProps
							And TableRow.Period < DecryptionString.Period
					Or TableRow.PriorityOfOrderingProps = DecryptionString.PriorityOfOrderingProps
							And TableRow.Period = DecryptionString.Period
							And TableRow.DemandDate < DecryptionString.DemandDate
					Or TableRow.PriorityOfOrderingProps = DecryptionString.PriorityOfOrderingProps
							And TableRow.Period = DecryptionString.Period
							And TableRow.DemandDate = DecryptionString.DemandDate
							And TableRow.WarehouseName < DecryptionString.WarehouseName Then
				
				Continue;
				
			Else
				
				If TableRow.PriorityOfOrderingProps = DecryptionString.PriorityOfOrderingProps
							And TableRow.Period = DecryptionString.Period
							And TableRow.DemandDate = DecryptionString.DemandDate
							And TableRow.WarehouseName = DecryptionString.WarehouseName
							And TableRow.Warehouse = DecryptionString.Warehouse Then
				
					FoundRow = TableRow;
					
				Else
					
					FoundRow = Object.GoodsDetails.Insert(Object.GoodsDetails.IndexOf(TableRow));
					FoundRow.ThisIsOutsideThePeriodLimit = True;
					
				EndIf;
				
				Break;
				
			EndIf;
			
		EndDo;
		
		If FoundRow = Undefined Then
			
			FoundRow = Object.GoodsDetails.Add();
			FoundRow.ThisIsOutsideThePeriodLimit = True;
			
		EndIf;
		
		FillPropertyValues(FoundRow, DecryptionString);
		FoundRow.ToMoveAlongRow = FoundRow.ForTransfer;
		
		If FoundRow.ForTransfer > 0 Then
			FoundRow.Mark = True;
		EndIf;
		
	EndDo;
	
EndProcedure
	
&AtServer
Procedure SetConditionalAppearance()
	
	// Registration of overdue dates of need.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDetailsPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsDetails.ThisIsShortage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	// Registration of the dates of the need abroad of the provided period.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDetails.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsDetails.ThisIsOutsideThePeriodLimit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	If Parameters.Mode = "StockAllocation" Then
		
		// Clearance To Move > Available.
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LabelToMove.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.GoodsDetails.ResultIsToMoveAlongLine");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
		ItemFilter.RightValue = New DataCompositionField("TheInscriptionIsAvailable");
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
		
	ElsIf Parameters.Mode = "Demand_fulfillment" Then
		
		// Clearance To Move > Need.
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.LabelToMove.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.GoodsDetails.ResultIsToMoveAlongLine");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
		ItemFilter.RightValue = New DataCompositionField("TheInscriptionNeed");
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
		
		// Clearance To Move > Available.
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.GoodsDetailsForTransfer.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.GoodsDetails.ToMoveAlongRow");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
		ItemFilter.RightValue = New DataCompositionField("Object.GoodsDetails.Available");
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
		
	EndIf;
	
EndProcedure

&AtServer
Function PutGoodsInTemporaryStorageDecryption()
	
	ValueTable = Object.GoodsDetails.Unload(
		New Structure("Mark", True),
		"PriorityOfOrderingProps, Period, DemandDate, WarehouseName, Warehouse, ForTransfer");
	
	Return PutToTempStorage(ValueTable);
	
EndFunction

#EndRegion
