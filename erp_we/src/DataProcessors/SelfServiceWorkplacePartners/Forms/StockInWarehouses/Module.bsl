
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Terms") Then
		Terms = Parameters.Terms;
	EndIf;
	
	If Parameters.Property("BucketData") Then
		CustomerShoppingCart.Load(Parameters.BucketData.Unload(,"Products,Characteristic,Package,NumberOfPackages"));
	EndIf;
	
	BalanceViewIsAvailable = SelfServiceServer.YouCanViewBalancesInSelection();
	
	Generate();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure Generate()

	AgreementWarehouse_ = Common.ObjectAttributeValue(Terms, "Warehouse");

	Query = New Query;

	junk = CustomerShoppingCart.Unload();
	junk.GroupBy("Products,Characteristic,Package", "NumberOfPackages");
	
	Query.SetParameter("CustomerShoppingCart", junk);
	Query.SetParameter("Warehouse", AgreementWarehouse_);
	Query.SetParameter("StringAvailableOnOrder",NStr("vi = 'Được phép theo đơn hàng';
													|ru = 'Доступно под заказ';
													|en = 'Available to order'; fa = 'Available to order';
													|it = 'Disponibile su richiesta';
													|pl = 'Dostępne do zamówienia';
													|tr = 'Sipariş üzerine mevcut'"));  
	Query.SetParameter("LineAccordingToGraph",NStr("vi = 'Theo biên';
													|ru = 'Согласно графика';
													|en = 'According to the schedule'; fa = 'According to the schedule';
													|it = 'In conformità del grafico';
													|pl = 'Zgodnie z harmonogramem';
													|tr = 'Programa göre'"));
	Query.SetParameter("LineNeedsToBeClarified",NStr("vi = 'Cần làm chính xác';
													|ru = 'Требует уточнения';
													|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
													|it = 'Richiede chiarimenti';
													|pl = 'Wymaga uściślenia';
													|tr = 'Netleştirme gerekiyor'"));
	Query.SetParameter("ThisServiceIsAvailable",NStr("vi = 'Dịch vụ sử dụng được';
													|ru = 'Услуга доступна';
													|en = 'The service is available'; fa = 'The service is available';
													|it = 'Servizio accessibile';
													|pl = 'Usługa jest dostępna';
													|tr = 'Hizmet erişilebilir'"));
	Query.SetParameter("JobLineIsAvailable",NStr("vi = 'Công việc khả dụng';
												|ru = 'Работа доступна';
												|en = 'Operation is available'; fa = 'Operation is available';
												|it = 'Lavoro accessibile';
												|pl = 'Praca jest dostępna';
												|tr = 'İş erişilebilir'"));
	Query.SetParameter("UseItemVariants", 
	           GetFunctionalOption("UseItemVariants"));
	Query.SetParameter("CurrentDate",      CurrentSessionDate());
	Query.SetParameter("CurrentDayStart",BegOfDay(CurrentSessionDate()));
	
	Query.Text = "
	|SELECT
	|	CustomerShoppingCart.Products,
	|	CustomerShoppingCart.Characteristic,
	|	CustomerShoppingCart.Package,
	|	CustomerShoppingCart.NumberOfPackages
	|INTO CustomerShoppingCart
	|FROM
	|	&CustomerShoppingCart AS CustomerShoppingCart
	|";
	
	Query.TempTablesManager = New TempTablesManager();
	Query.Execute();
	
	Query.Text = "
	|SELECT ALLOWED DISTINCT
	|	Warehouses.Ref,
	|	Warehouses.Description,
	|	Warehouses.AvailableStockControl,
	|	Warehouses.IsFolder
	|INTO Warehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		LEFT JOIN Catalog.Warehouses AS WarehousesParameter
	|		ON (TRUE)
	|WHERE
	|	CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE CASE
	|					WHEN ISNULL(WarehousesParameter.IsFolder, FALSE)
	|						THEN Warehouses.Ref IN HIERARCHY (&Warehouse)
	|					ELSE Warehouses.Ref = &Warehouse
	|				END
	|		END
	|	AND CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE WarehousesParameter.Ref = &Warehouse
	|		END
	|	AND CASE
	|			WHEN Warehouses.IsFolder
	|					AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.Disable)
	|				THEN FALSE
	|			ELSE TRUE
	|		END
	|";
	
	Query.Execute();
	
	Query.Text = "
	|SELECT DISTINCT 
	|	Warehouses.Ref AS Warehouse,
	|	CustomerShoppingCart.Products,
	|	CustomerShoppingCart.Characteristic
	|INTO AllGoodsAndWarehouses
	|FROM
	|	Warehouses AS Warehouses,
	|	CustomerShoppingCart AS CustomerShoppingCart";

	Query.Execute();
	
	Texts = New Array();
	
	Text = InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE");
	Text = StrReplace(Text, "TTProducts_1", "AllGoodsAndWarehouses");
	Text = StrReplace(Text, "ALLOWED", "");
	Texts.Add(Text);
	
	Texts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
	
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	CalculationOfDeliveryDateOverridable.PlannedDeliveryDate AS Date
		|INTO TTScheduledDeliveryDate
		|FROM
		|	TTWaysToEnsure AS Table
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|WHERE
		|	Table.ProcurementStrategy <> VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|INDEX BY
		|	Products,Characteristic,Warehouse
		|;
		|
		|/////////////////////////////////
		|DROP TTWaysToEnsure";
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
		"Table.ProcurementStrategy",
		"&CurrentDayStart",
		"Table.Products",
		"Table.Warehouse");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text = DataProcessors.SelfServiceWorkplacePartners.TemporaryTablesForCalculatingAvailableBalances("AllGoodsAndWarehouses")
		+ DataProcessors.SelfServiceWorkplacePartners.TemporaryTableAvailableForSaleTotalByWarehouse("AllGoodsAndWarehouses")
		+ Common.QueryBatchSeparator()
		+"SELECT
		|	AllGoodsAndWarehouses.Products,
		|	AllGoodsAndWarehouses.Characteristic,
		|	AllGoodsAndWarehouses.Warehouse AS Warehouse,
		|	ISNULL(AvailableBalancesByDate.Count, 0) AS Available,
		|	ISNULL(UpcomingAvailabilityDates.Date, DATETIME(1, 1, 1)) AS Period,
		|	ISNULL(ProductRestrictions.InventoryReplenishmentMethod, VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)) AS MUSES
		|INTO DataOnIMUZAvailability
		|FROM
		|	AllGoodsAndWarehouses AS AllGoodsAndWarehouses
		|		
		|		LEFT JOIN TTUpcomingAvailabilityDates AS UpcomingAvailabilityDates
		|		ON UpcomingAvailabilityDates.Products   = AllGoodsAndWarehouses.Products
		|		 AND UpcomingAvailabilityDates.Characteristic = AllGoodsAndWarehouses.Characteristic
		|		 AND UpcomingAvailabilityDates.Warehouse          = AllGoodsAndWarehouses.Warehouse
		|		
		|		LEFT JOIN TTAvailableBalancesByDate AS AvailableBalancesByDate
		|		ON AvailableBalancesByDate.Products   = AllGoodsAndWarehouses.Products
		|		 AND AvailableBalancesByDate.Characteristic = AllGoodsAndWarehouses.Characteristic
		|		 AND AvailableBalancesByDate.Warehouse          = AllGoodsAndWarehouses.Warehouse
		|		 AND AvailableBalancesByDate.Period         = UpcomingAvailabilityDates.Date
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON &SubstituteGoodsRestriction
		|;
		|
		|//////////////////////////////////////////////////////////
		|
		|SELECT
		|	DataOnIMUZAvailability.Warehouse AS Warehouse,
		|	DataOnIMUZAvailability.Products AS Products,
		|	DataOnIMUZAvailability.Characteristic AS Characteristic,
		|	DataOnIMUZAvailability.Period AS Period,
		|	DataOnIMUZAvailability.Available AS Available,
		|	DataOnIMUZAvailability.Available AS AvailableNow,
		|	ISNULL(DatesOfScheduledDelivery.Date, DATETIME(1, 1, 1))  AS ShipmentDate,
		|	CASE
		|		WHEN ItemKinds.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|			THEN &ThisServiceIsAvailable
		|		WHEN ItemKinds.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &JobLineIsAvailable
		|		WHEN DataOnIMUZAvailability.MUSES = VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
		|			THEN &StringAvailableOnOrder
		|		WHEN NOT CAST(DataOnIMUZAvailability.Warehouse AS Catalog.Warehouses).AvailableStockControl
		|			 THEN &LineNeedsToBeClarified
		|		ELSE &LineAccordingToGraph
		|	END AS Enabled,
		|	CAST(CASE WHEN DataOnIMUZAvailability.Period = &CurrentDayStart THEN
		|					ISNULL(DataOnIMUZAvailability.Available, 0)
		|				ELSE
		|				0
		|				END / ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15, 3)) AS AvailableBalanceNow,
		|	CustomerShoppingCart.Package AS Package,
		|	CustomerShoppingCart.NumberOfPackages AS NumberOfPackages,
		|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
		|	CASE
		|		WHEN ProductPackages.Ref IS NULL 
		|			THEN CustomerShoppingCart.NumberOfPackages
		|		ELSE CustomerShoppingCart.NumberOfPackages * &QueryTextPackagingFactor
		|	END AS Count
		|FROM
		|	DataOnIMUZAvailability AS DataOnIMUZAvailability
		|		INNER JOIN Warehouses AS Warehouses
		|		ON DataOnIMUZAvailability.Warehouse = Warehouses.Ref
		|		INNER JOIN CustomerShoppingCart AS CustomerShoppingCart
		|			LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|			ON CustomerShoppingCart.Package = ProductPackages.Ref
		|		ON DataOnIMUZAvailability.Products = CustomerShoppingCart.Products
		|			AND DataOnIMUZAvailability.Characteristic = CustomerShoppingCart.Characteristic
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|			LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|			ON CatalogProducts.ProductKind = ItemKinds.Ref
		|		ON DataOnIMUZAvailability.Products = CatalogProducts.Ref
		|		
		|		LEFT JOIN TTScheduledDeliveryDate AS DatesOfScheduledDelivery
		|		ON DatesOfScheduledDelivery.Products = DataOnIMUZAvailability.Products
		|		 AND DatesOfScheduledDelivery.Characteristic = DataOnIMUZAvailability.Characteristic
		|		 AND DatesOfScheduledDelivery.Warehouse = DataOnIMUZAvailability.Warehouse
		|		
		|ORDER BY
		|	DataOnIMUZAvailability.Warehouse.Description
		|TOTALS BY
		|	Products,
		|	Characteristic,
		|	Package,
		|	UnitOfMeasure,
		|	NumberOfPackages,
		|	Warehouse";
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductPackages",
				"CatalogProducts"));
				
	ConnectionFields = "AllGoodsAndWarehouses.Products,AllGoodsAndWarehouses.Characteristic,AllGoodsAndWarehouses.Warehouse";
	Query.Text = InformationRegisters.ProductRestrictions.SubstituteConnection(Query.Text, "SubstituteGoodsRestriction", ConnectionFields);
	
	SetPrivilegedMode(True);
		Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text = "
	|SELECT DISTINCT
	|	Warehouses.Ref,
	|	Warehouses.Description
	|FROM
	|	Warehouses AS Warehouses
	|
	|ORDER BY
	|	Warehouses.Description
	|";

	ResultWarehouses = Query.Execute();
	Query.TempTablesManager.Close();

	If ResultWarehouses.IsEmpty() Then
		Return;
	EndIf;
	
	WarehouseHierarchyQuery = New Query;
	WarehouseHierarchyQuery.Text = "
	|SELECT ALLOWED DISTINCT
	|	Warehouses.Ref AS Warehouse,
	|	Warehouses.IsFolder AS IsFolder
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|	LEFT JOIN Catalog.Warehouses AS WarehousesParameter
	|		ON (TRUE)
	|WHERE
	|	CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE CASE
	|					WHEN ISNULL(WarehousesParameter.IsFolder, FALSE)
	|						THEN Warehouses.Ref IN HIERARCHY (&Warehouse)
	|					ELSE Warehouses.Ref = &Warehouse
	|				END
	|		END
	|	AND CASE
	|			WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				THEN TRUE
	|			ELSE WarehousesParameter.Ref = &Warehouse
	|		END
	|	AND CASE
	|			WHEN Warehouses.IsFolder
	|					AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.Disable)
	|				THEN FALSE
	|			ELSE TRUE
	|		END
	|TOTALS BY
	|	Warehouse HIERARCHY,
	|	IsFolder";


	AgreementWarehouse_ = Common.ObjectAttributeValue(Terms, "Warehouse");
	WarehouseHierarchyQuery.SetParameter("Warehouse", AgreementWarehouse_);
	
	If Not Result.IsEmpty() Then
		Put(Result, ResultWarehouses, WarehouseHierarchyTable(WarehouseHierarchyQuery.Execute()));
	EndIf;

EndProcedure

&AtServer
Procedure Put(QueryResult,ResultOfWarehousesRequest, TableOfWarehouseGroups)
	
	SpreadsheetDocument.Clear();
	
	UsingProductCharacteristics = GetFunctionalOption("UseItemVariants");
	
	Template = DataProcessors.SelfServiceWorkplacePartners.GetTemplate("StockInWarehouses");
	
	AreaProductHeader              = Template.GetArea("Header|Products");
	AreaHeaderCharacteristic            = Template.GetArea("Header|Characteristic");
	AreaCapPackingQuantity        = Template.GetArea("Header|PackingQuantity_");
	WarehouseHeaderArea                     = Template.GetArea(?(BalanceViewIsAvailable, "Header|WarehouseBalance", "Header|Warehouse"));
	
	ScopeAndProducts             = Template.GetArea("String|Products");
	ScopeAndCharacteristics           = Template.GetArea("String|Characteristic");
	ScopeStringPackingQuantity       = Template.GetArea("String|PackingQuantity_");
	AreaLineWarehouse                    = Template.GetArea(?(BalanceViewIsAvailable, "String|WarehouseBalance", "String|Warehouse"));
	AreaOfRowIsNegative       = Template.GetArea(?(BalanceViewIsAvailable, "StringNegativeNumber|WarehouseBalance", "StringNegativeNumber|Warehouse"));
	
	// The header of the report
	SpreadsheetDocument.Put(AreaProductHeader);
	If UsingProductCharacteristics Then
		SpreadsheetDocument.Join(AreaHeaderCharacteristic);
	EndIf;
	
	SpreadsheetDocument.Join(AreaCapPackingQuantity);
	SampleWarehouses = ResultOfWarehousesRequest.Select();
	While SampleWarehouses.Next() Do
		
		WarehouseHeaderArea.Parameters.Warehouse = SampleWarehouses.Description;
		SpreadsheetDocument.Join(WarehouseHeaderArea);
		
	EndDo;
	
	LineNumber = 0;
	
	SelectionOfProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionOfProducts.Next() Do
		SampleCharacteristics = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
		While SampleCharacteristics.Next() Do
			SamplePackaging = SampleCharacteristics.Select(QueryResultIteration.ByGroups);
			While SamplePackaging.Next() Do
				SampleUnits = SamplePackaging.Select(QueryResultIteration.ByGroups);
				While SampleUnits.Next() Do
					
					SampleQuantity = SampleUnits.Select(QueryResultIteration.ByGroups);
					While SampleQuantity.Next() Do
						LineNumber = LineNumber + 1;
						ScopeAndProducts.Parameters.LineNumber  = LineNumber;
						ScopeAndProducts.Parameters.Products = SelectionOfProducts.Products;
						SpreadsheetDocument.Put(ScopeAndProducts);
						If UsingProductCharacteristics Then
							ScopeAndCharacteristics.Parameters.Characteristic = SampleCharacteristics.Characteristic;
							SpreadsheetDocument.Join(ScopeAndCharacteristics);
						EndIf;
						ScopeStringPackingQuantity.Parameters.Package = 
						    ?(SampleQuantity.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(),
						      SampleQuantity.UnitOfMeasure,
						      String(SampleQuantity.Package)+ ","+ String(SampleQuantity.UnitOfMeasure));
						ScopeStringPackingQuantity.Parameters.Count = SampleQuantity.NumberOfPackages;
						SpreadsheetDocument.Join(ScopeStringPackingQuantity);
						ClearDependentColumnsWarehouseTable(TableOfWarehouseGroups);
						ComplianceWarehouseData = New Map;
						SampleWarehouse = SampleQuantity.Select(QueryResultIteration.ByGroups);
						While SampleWarehouse.Next() Do
							DetailsSelection = SampleWarehouse.Select();
							While DetailsSelection.Next() Do
								AccessibilityValue_ = DetailsSelection.Enabled;
								If DetailsSelection.Enabled = NStr("vi = 'Theo biên';
																	|ru = 'Согласно графика';
																	|en = 'According to the schedule'; fa = 'According to the schedule';
																	|it = 'In conformità del grafico';
																	|pl = 'Zgodnie z harmonogramem';
																	|tr = 'Programa göre'") Then

									If DetailsSelection.Available > 0 Then

										If DetailsSelection.Period = BegOfDay(CurrentSessionDate()) Then

											If DetailsSelection.Count/DetailsSelection.Available < 0.5 Then
												AccessibilityValue_ = NStr("vi = 'Có sẵn';
																			|ru = 'В наличии';
																			|en = 'In stock'; fa = 'موجود در انبار';
																			|it = 'In disposizione';
																			|pl = 'Dostępny towar';
																			|tr = 'Stokta'");
												AddToWarehousesComplianceRecord(ComplianceWarehouseData, DetailsSelection.Warehouse, AccessibilityValue_, DetailsSelection.AvailableBalanceNow);
											Else
												AccessibilityValue_ = NStr("vi = 'Cần làm chính xác';
																			|ru = 'Требует уточнения';
																			|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
																			|it = 'Richiede chiarimenti';
																			|pl = 'Wymaga uściślenia';
																			|tr = 'Netleştirme gerekiyor'");
												AddToWarehousesComplianceRecord(ComplianceWarehouseData, DetailsSelection.Warehouse, AccessibilityValue_, DetailsSelection.AvailableBalanceNow);
											EndIf;

										Else
											AccessibilityValue_ = NStr("vi = 'Đang chờ';
																		|ru = 'Ожидается';
																		|en = 'Expected'; fa = 'مورد انتظار';
																		|it = 'Previsto';
																		|pl = 'Oczekiwane';
																		|tr = 'Beklenen'") + " " + Format(DetailsSelection.Period,"DLF=D");
											AddToWarehousesComplianceRecord(ComplianceWarehouseData, DetailsSelection.Warehouse, AccessibilityValue_, DetailsSelection.AvailableBalanceNow, DetailsSelection.Period);
										EndIf;

									Else

										If DetailsSelection.ShipmentDate < BegOfDay(CurrentSessionDate()) Then
											AccessibilityValue_ = NStr("vi = 'Không có trong kho';
																		|ru = 'Нет на складе';
																		|en = 'Out of stock'; fa = 'Out of stock';
																		|it = 'Non in magazzino';
																		|pl = 'Niema w magazynie';
																		|tr = 'Ambarda mevcut değil'");
											AddToWarehousesComplianceRecord(ComplianceWarehouseData, DetailsSelection.Warehouse, AccessibilityValue_, DetailsSelection.AvailableBalanceNow);
										Else
											AccessibilityValue_ = NStr("vi = 'Đang chờ';
																		|ru = 'Ожидается';
																		|en = 'Expected'; fa = 'مورد انتظار';
																		|it = 'Previsto';
																		|pl = 'Oczekiwane';
																		|tr = 'Beklenen'") + " " + Format(DetailsSelection.ShipmentDate,"DLF=D");
											AddToWarehousesComplianceRecord(ComplianceWarehouseData, DetailsSelection.Warehouse, AccessibilityValue_, DetailsSelection.AvailableBalanceNow, DetailsSelection.ShipmentDate);
										EndIf;

									EndIf;

								Else
									AddToWarehousesComplianceRecord(ComplianceWarehouseData, DetailsSelection.Warehouse, AccessibilityValue_, DetailsSelection.AvailableBalanceNow);
								EndIf;
								
								If AccessibilityValue_ = NStr("vi = 'Không có trong kho';
																|ru = 'Нет на складе';
																|en = 'Out of stock'; fa = 'Out of stock';
																|it = 'Non in magazzino';
																|pl = 'Niema w magazynie';
																|tr = 'Ambarda mevcut değil'") Then
									AreaOfRowIsNegative.Parameters.Enabled = AccessibilityValue_;
									If BalanceViewIsAvailable Then
										AreaOfRowIsNegative.Parameters.AvailableBalance = ?(DetailsSelection.AvailableBalanceNow < 0, 0, DetailsSelection.AvailableBalanceNow);
									EndIf;
									CellArea = SpreadsheetDocument.Join(AreaOfRowIsNegative);
								Else
									AreaLineWarehouse.Parameters.Enabled = AccessibilityValue_;
									If BalanceViewIsAvailable Then
										AreaLineWarehouse.Parameters.AvailableBalance = ?(DetailsSelection.AvailableBalanceNow < 0, 0, DetailsSelection.AvailableBalanceNow);
									EndIf;
									CellArea = SpreadsheetDocument.Join(AreaLineWarehouse);
								EndIf;
								
								RowInWarehouseGroupTable = TableOfWarehouseGroups.Find(DetailsSelection.Warehouse, "Warehouse");
								If RowInWarehouseGroupTable <> Undefined Then
									RowInWarehouseGroupTable.Area = CellArea;
								EndIf;
								
							EndDo; //DetailsSelection
						EndDo; //SampleWarehouses
						
						FillInAvailabilityOfWarehouseGroup(TableOfWarehouseGroups, ComplianceWarehouseData);
						
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	If UsingProductCharacteristics Then
		SpreadsheetDocument.FixedLeft = 3;
	Else
		SpreadsheetDocument.FixedLeft = 2;
	EndIf;
	
EndProcedure

// Parameters:
// 	TableOfWarehouseGroups - See WarehouseHierarchyTable
// 	ComplianceWarehouseData - Map - Contains:
//		* Key - CatalogRef.Warehouses - 
//		* Value - See WarehouseData_
&AtServer
Procedure FillInAvailabilityOfWarehouseGroup(TableOfWarehouseGroups, ComplianceWarehouseData);
	
	ArrayOfAccessibilityTexts = SelfServiceServer.ArrayOfAccessibilityTexts();
	
	For Each RowInWarehouseGroupTable In TableOfWarehouseGroups Do
		
		TextAvailability = "";
		TextAvailabilityNow = "";
		
		AvailabilityDate  = Undefined;
		For Each ArrayElement In RowInWarehouseGroupTable.ArrayOfSubordinateWarehouses Do
			WarehouseData_1 = ComplianceWarehouseData.Get(ArrayElement); // See WarehouseData_
			If WarehouseData_1 <> Undefined Then
				If WarehouseData_1.Enabled = NStr("vi = 'Có sẵn';
													|ru = 'В наличии';
													|en = 'In stock'; fa = 'موجود در انبار';
													|it = 'In disposizione';
													|pl = 'Dostępny towar';
													|tr = 'Stokta'")
					Or WarehouseData_1.Enabled = NStr("vi = 'Sử dụng được dịch vụ';
														|ru = 'Услуга доступна';
														|en = 'The service is available'; fa = 'The service is available';
														|it = 'Servizio accessibile';
														|pl = 'Usługa jest dostępna';
														|tr = 'Hizmet erişilebilir'") Then
					TextAvailability = WarehouseData_1.Enabled;
					Break;
				Else
					
					If TextAvailability = "" Then
						TextAvailability = WarehouseData_1.Enabled;
					Else
						NumberInGroupArray  = ArrayOfAccessibilityTexts.Find(TextAvailability);
						NumberInArrayIsCur = ArrayOfAccessibilityTexts.Find(WarehouseData_1.Enabled);
						If NumberInGroupArray = Undefined Or NumberInArrayIsCur = Undefined Then
							Continue;
						EndIf;
						If NumberInArrayIsCur <= NumberInGroupArray Then
							TextAvailability = WarehouseData_1.Enabled;
						Else
							Continue;
						EndIf;
					EndIf;
					
					If WarehouseData_1.Enabled = NStr("vi = 'Đang chờ';
														|ru = 'Ожидается';
														|en = 'Expected'; fa = 'مورد انتظار';
														|it = 'Previsto';
														|pl = 'Expected';
														|tr = 'Beklenen'") + " " Then
						If AvailabilityDate = Undefined Then
							AvailabilityDate =WarehouseData_1.AvailabilityPeriod;
						ElsIf AvailabilityDate > WarehouseData_1.AvailabilityPeriod Then
							AvailabilityDate = WarehouseData_1.AvailabilityDate;
						EndIf;
					EndIf;
					
				EndIf;
			EndIf;
		EndDo;
		
		AvailableNow = 0;
		
		If BalanceViewIsAvailable Then
			For Each ArrayElement In RowInWarehouseGroupTable.ArrayOfSubordinateWarehouses Do
				WarehouseData_1 = ComplianceWarehouseData.Get(ArrayElement);
				If WarehouseData_1 <> Undefined Then
					AvailableNow = AvailableNow + WarehouseData_1.AvailableBalanceNow;
				EndIf;
			EndDo;
		EndIf;
		
		If AvailableNow < 0 Then
			AvailableNow = 0;
		EndIf;
		
		If TextAvailability = NStr("vi = 'Đang chờ';
									|ru = 'Ожидается';
									|en = 'Expected'; fa = 'مورد انتظار';
									|it = 'Previsto';
									|pl = 'Expected';
									|tr = 'Beklenen'") + " " Then
			 TextAvailability = TextAvailability + Format(AvailabilityDate, "DLF=D");
		EndIf;
		
		If IsBlankString(TextAvailability) Then
			TextAvailability = NStr("vi = 'Không có';
									|ru = 'Нет в наличии';
									|en = 'Not available'; fa = 'در دسترس نیست';
									|it = 'Non è disponibile';
									|pl = 'Brak';
									|tr = 'Stokta yok'");
		EndIf;
		
		If RowInWarehouseGroupTable.Area <> Undefined Then
			If BalanceViewIsAvailable Then
				Area = RowInWarehouseGroupTable.Area; // SpreadsheetDocumentRange
				ArrayOfAreaNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Area.Name, ":");
				AreaAvailability    = SpreadsheetDocument.Area(ArrayOfAreaNames[0]);
				FieldAvailableNow = SpreadsheetDocument.Area(ArrayOfAreaNames[1]);
			Else
				AreaAvailability = RowInWarehouseGroupTable.Area;
				FieldAvailableNow = Undefined;
			EndIf;
			
			If FieldAvailableNow <> Undefined Then
				FieldAvailableNow.Text = AvailableNow;
			EndIf;
			AreaAvailability.Text = TextAvailability;
			
			If TextAvailability = NStr("vi = 'Không có';
										|ru = 'Нет в наличии';
										|en = 'Not available'; fa = 'در دسترس نیست';
										|it = 'Non è disponibile';
										|pl = 'Brak';
										|tr = 'Stokta yok'") Then
				AreaAvailability.TextColor = StyleColors.NegativeTextColor;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddToWarehousesComplianceRecord(Map, Warehouse, Var_Enabled, AvailableBalanceNow, AvailabilityPeriod = Undefined)
	
	WarehouseDataStructure = WarehouseData_();
	WarehouseDataStructure.Enabled = Var_Enabled;
	WarehouseDataStructure.AvailabilityPeriod = AvailabilityPeriod;
	WarehouseDataStructure.AvailableBalanceNow = AvailableBalanceNow;
	
	Map.Insert(Warehouse, WarehouseDataStructure);
	
EndProcedure

// Function-constructor of the "warehouse data" structure for output to the report.
// 
// Returns:
//  Structure - Contains:
//   * AvailableBalanceNow  - String -
//   * AvailabilityPeriod       - Date -
//   * Enabled             - String -
//
&AtServer
Function WarehouseData_()
	
	Result = New Structure;
	Result.Insert("Enabled",            Undefined);
	Result.Insert("AvailabilityPeriod",      Undefined);
	Result.Insert("AvailableBalanceNow", Undefined);
	
	Return Result;
	
EndFunction

// Parameters:
// 	QueryResult - QueryResult, Undefined - 
// Returns:
// 	ValueTable - Contains:
// * Warehouse                      - CatalogRef.Warehouses - 
// * ArrayOfSubordinateWarehouses   - Array of CatalogRef.Warehouses -
// * AccessibilityText           - String -
// * Area                    - String -
&AtServer
Function WarehouseHierarchyTable(QueryResult)

	WarehouseTable = New ValueTable;
	WarehouseTable.Columns.Add("Warehouse");
	WarehouseTable.Columns.Add("ArrayOfSubordinateWarehouses");
	WarehouseTable.Columns.Add("AccessibilityText");
	WarehouseTable.Columns.Add("Area");
	
	WarehouseTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	AddWarehousesToTableByTreeRows(WarehouseTree.Rows, Undefined, WarehouseTable, New Array);
	
	Return WarehouseTable;
	
EndFunction

&AtServer
Procedure AddWarehousesToTableByTreeRows(TreeRows, Warehouse,  WarehouseTable, WarehouseArray)

	CurWarehouseArray = CommonClientServer.CopyArray(WarehouseArray);
	If Warehouse <> Undefined Then
		CurWarehouseArray.Add(Warehouse);
	EndIf;
	
	For Each TreeRow In TreeRows Do
		
		If TreeRow.IsFolder Then
			If WarehouseTable.Find(TreeRow.Warehouse, "Warehouse") = Undefined Then
				NewTableRow = WarehouseTable.Add();
				NewTableRow.Warehouse = TreeRow.Warehouse;
				NewTableRow.ArrayOfSubordinateWarehouses = New Array;
				AddWarehousesToTableByTreeRows(TreeRow.Rows, TreeRow.Warehouse, WarehouseTable, CurWarehouseArray);
			EndIf;
		Else
			For Each ArrayElement In CurWarehouseArray Do
				TableRow = WarehouseTable.Find(ArrayElement, "Warehouse");
				If TableRow <> Undefined Then
					ArrayOfSubordinateWarehouses = TableRow.ArrayOfSubordinateWarehouses; // Array
					ArrayOfSubordinateWarehouses.Add(TreeRow.Warehouse);
				EndIf;
			EndDo
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure ClearDependentColumnsWarehouseTable(WarehouseTable)

	WarehouseTable.FillValues("", "AccessibilityText");
	WarehouseTable.FillValues(Undefined, "Area");

EndProcedure

#EndRegion
