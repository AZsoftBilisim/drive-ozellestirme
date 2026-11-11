#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Selects the cell for placing the goods on the address of the warehouse.
//
// Parameters:
// 		SourceName - String - name of the table part.
//
Procedure PlaceProducts(SourceName) Export
	
	FillInVerificationParameters(SourceName);
	
	If CheckFilling() Then
		
		Manager = New TempTablesManager;
		Query = New Query;
		Query.TempTablesManager = Manager;
		Query.Text =
		"SELECT
		|	RequestProductTable.Products AS Products,
		|	RequestProductTable.Package AS Package,
		|	RequestProductTable.Characteristic AS Characteristic,
		|	RequestProductTable.Purpose AS Purpose,
		|	CAST(RequestProductTable.Series AS Catalog.ItemsBatches) AS Series,
		|	RequestProductTable.NumberOfPackages AS NumberOfPackages
		|INTO RequestProductTable
		|FROM
		|	&Goods AS RequestProductTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RequestProductTable.Products AS Products,
		|	RequestProductTable.Package AS Package,
		|	RequestProductTable.Series,
		|	RequestProductTable.Characteristic AS Characteristic,
		|	RequestProductTable.Purpose AS Purpose,
		|	SUM(RequestProductTable.NumberOfPackages) AS NumberOfPackages
		|INTO ProductsTable
		|FROM
		|	RequestProductTable AS RequestProductTable
		|
		|GROUP BY
		|	RequestProductTable.Products,
		|	RequestProductTable.Package,
		|	RequestProductTable.Characteristic,
		|	RequestProductTable.Purpose,
		|	RequestProductTable.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RequestProductTable";
	
		TableForPlacement = ThisObject[SourceName].Unload(,"Products,Package,Characteristic,Purpose,Series,NumberOfPackages");
		Query.SetParameter("Goods",TableForPlacement);
		Query.SetParameter("Warehouse",Warehouse);
		
		Query.Execute();
		
		CheckError = False;
		
		ReturnStructure = WarehousesServer.PlaceGoodsInCells(
			Manager,
			Warehouse,
			Premise,
			?(OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location, 
				WarehouseZone, 
				Catalogs.WarehouseZones.EmptyRef()),
			Catalogs.StorageBins.EmptyRef(),
			CheckError);
		
		Manager.Close();
		
		If Not CheckError Then
			
			GoodsPlacement.Clear();
			
			For Each RowOfTables In ReturnStructure.ErrorsTable Do
				
				If RowOfTables.NumberOfPackages > 0 Then
					
					NewRow = GoodsPlacement.Add();
					
					FillPropertyValues(NewRow,RowOfTables);
					
				EndIf;
				
			EndDo;
			
			ReturnStructure.ResultsTable.Sort("Cell Asc, Products Desc, Characteristic Desc");
			
			For Each RowOfTables In ReturnStructure.ResultsTable Do
				
				If RowOfTables.NumberOfPackages > 0 Then
					
					NewRow = GoodsPlacement.Add();
					
					FillPropertyValues(NewRow,RowOfTables);
					
				EndIf;
				
			EndDo;
			
		EndIf;
	EndIf;
	
	AdditionalProperties.Delete("CheckParameters");
EndProcedure

// Selects the cells for the selection of the goods with the address of the warehouse.
//
// Parameters:
// 		SourceName - String - name of the table part.
//
Procedure PickUpProducts(SourceName) Export
	
	FillInVerificationParameters(SourceName);
	
	If CheckFilling() Then
		
		Manager = New TempTablesManager;
		
		If OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
			
			Query = New Query;
			Query.TempTablesManager = Manager;
			Query.Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Purpose AS Purpose,
			|	Table.Series AS Series,
			|	Table.Count AS Count
			|INTO RequestProductTable
			|FROM
			|	&Goods AS Table
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RequestProductTable.Products,
			|	RequestProductTable.Characteristic,
			|	RequestProductTable.Purpose,
			|	RequestProductTable.Series,
			|	SUM(RequestProductTable.Count) AS Count,
			|	DATETIME(1, 1, 1) AS DateOfShipment,
			|	0 AS Priority,
			|	&ReferenceOrder AS ReferenceOrder,
			|	CAST(RequestProductTable.Products AS Catalog.Products).WarehouseGroup AS WarehouseGroupOfProducts
			|INTO ProductsTable
			|FROM
			|	RequestProductTable AS RequestProductTable
			|
			|GROUP BY
			|	RequestProductTable.Products,
			|	RequestProductTable.Characteristic,
			|	RequestProductTable.Purpose,
			|	RequestProductTable.Series
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP RequestProductTable";
			
			TableForPlacement = ThisObject[SourceName].Unload(,"Products,Characteristic,Purpose,Series,Count");
			
			Query.SetParameter("Goods",TableForPlacement);
			Query.SetParameter("ReferenceOrder",?(ValueIsFilled(ReferenceOrder),ReferenceOrder,""));
			
			Query.Execute();
			
			CheckError = False;
			
			ReturnStructure = WarehousesServer.SelectProductFromCells(Manager,Warehouse,Premise);
			
			
		Else
			
			WarehousesServer.RemainingGoodsForSelection(Manager, ReferenceOrder, Warehouse, Premise);
			
			CheckError = False;
			
			ReturnStructure = WarehousesServer.SelectProductFromCells(Manager,Warehouse,Premise);
			
		EndIf;
		
		Manager.Close();
		
		GoodsFilter.Clear();
		
		For Each RowOfTables In ReturnStructure.ErrorsTable Do
			
			If RowOfTables.Count > 0 Then
				
				NewRow = GoodsFilter.Add();
				
				FillPropertyValues(NewRow,RowOfTables);
				
				If NewRow.NumberOfPackages = 0 Then
					NewRow.NumberOfPackages = NewRow.Count;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		For Each RowOfTables In ReturnStructure.ResultsTable Do
			
			If RowOfTables.Count > 0 Then
				
				NewRow = GoodsFilter.Add();
				
				FillPropertyValues(NewRow,RowOfTables);
				
			EndIf;
			
		EndDo;
			
	EndIf;
	
	AdditionalProperties.Delete("CheckParameters");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	If Not (FillingData <> Undefined
		And Documents.AllRefsType().ContainsType(TypeOf(FillingData))) Then
		Return;
	EndIf;
	
	If Not FillingData.Posted Then
		MessageText = NStr("vi = 'Chỉ có thể nhập trên cơ sở theo chứng từ đã kết chuyển!';
							|ru = 'Ввод на основании возможен только по проведенным документам!';
							|en = 'You can generate a document only from a posted document.'; fa = 'You can generate a document only from a posted document.';
							|it = 'L''inserimento nella ricevuta è possibile solamente attraverso i documenti già emessi!';
							|pl = 'Wstęp na podstawie jest możliwy tylko na podstawie zaksięgowanych dokumentów!';
							|tr = 'Esaslı giriş, yalnızca kaydedilen belgelere göre mümkündür!'");
		Raise MessageText;
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsReceiptNote") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,
			"Status, Warehouse, Premise, ReceivingArea, Date");
		
		If DetailsOfFoundation.Status <> Enums.GoodsReceiptNoteStatuses.Accepted  Then
			MessageText = NStr("vi = 'Cho phép nhập nhiệm vụ xếp xếp vào trên cơ sở phiếu thu với trạng thái ""%NoteStatus%"".';
								|ru = 'Ввод заданий на размещение допускается на основании приходных ордеров в статусе ""%NoteStatus%"".';
								|en = 'You can generate a Put-away task only from an Inbound delivery with status ""%NoteStatus%"".'; fa = 'You can generate a Put-away task only from an Inbound delivery with status ""%NoteStatus%"".';
								|it = 'L''immissione di incarichi per il collocamento è consentita sulla base dei reversali d’incasso nello stato ""%NoteStatus%"".';
								|pl = 'Wprowadzenie zadań na rozmieszczenie na podstawie asygnat przychodowych w statusie ""%NoteStatus%"".';
								|tr = '""%NoteStatus%"" statüsünde ambar giriş fişi olan siparişler esasında yerleştirme görevleri girilebilir.'");
			MessageText = StrReplace(MessageText,"%NoteStatus%", Enums.GoodsReceiptNoteStatuses.Accepted);
			Raise MessageText;
		EndIf;

		If Not WarehousesServer.UseBinLocationWarehousing(DetailsOfFoundation.Warehouse, DetailsOfFoundation.Premise, DetailsOfFoundation.Date) Then
			MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" không sử dụng cơ chế lưu địa chỉ hàng hóa';
								|ru = 'На складе ""%Warehouse%"" не используется адресное хранение остатков';
								|en = 'Bin location system is disabled for warehouse ""%Warehouse%""'; fa = 'Bin location system is disabled for warehouse ""%Warehouse%""';
								|it = 'Nel magazzino ""%Warehouse%"" non viene utilizzato stoccaggio delle rimanenze codificato';
								|pl = 'W magazynie ""%Warehouse%"" nie jest używane adresowe przechowywanie ostatków';
								|tr = '""%Warehouse%"" ambarında, bakiyelerin depo konum takibi kullanılmıyor'");
			MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(DetailsOfFoundation.Warehouse, DetailsOfFoundation.Premise));
			Raise MessageText;
		EndIf;
		
		OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location;
		
		FillPropertyValues(ThisObject,DetailsOfFoundation, "ReceivingArea, Warehouse, Premise");
		
		Query = New Query;
		QueryText =
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	GoodsTable.Products.Description AS NomenclatureName,
		|	GoodsTable.Characteristic.Description AS CharacteristicName
		|INTO TTTableProducts
		|FROM
		|	Document.GoodsReceiptNote.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Count <> 0
		|	AND NOT GoodsTable.ThisIsAPackingList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTTableProducts.Products AS Products,
		|	TTTableProducts.Characteristic AS Characteristic,
		|	TTTableProducts.Purpose AS Purpose,
		|	TTTableProducts.Package AS Package,
		|	SUM(TTTableProducts.NumberOfPackages) AS NumberOfPackages,
		|	SUM(TTTableProducts.Count) AS Count,
		|	TTTableProducts.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	TTTableProducts.Series AS Series,
		|	&QueryTextWeight AS Weight,
		|	&QueryTextVolumeM3 AS VolumeM3,
		|	TTTableProducts.NomenclatureName AS NomenclatureName,
		|	TTTableProducts.CharacteristicName AS CharacteristicName
		|FROM
		|	TTTableProducts AS TTTableProducts
		|
		|GROUP BY
		|	TTTableProducts.Series,
		|	TTTableProducts.NomenclatureName,
		|	TTTableProducts.CharacteristicName,
		|	TTTableProducts.Products,
		|	TTTableProducts.Characteristic,
		|	TTTableProducts.Purpose,
		|	TTTableProducts.Package,
		|	TTTableProducts.BatchesIndicationStatus,
		|	&QueryTextWeight,
		|	&QueryTextVolumeM3
		|ORDER BY
		|	NomenclatureName,
		|	CharacteristicName";
		
		QueryText = StrReplace(
			QueryText, 
			"&QueryTextWeight", 
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("TTTableProducts.Package", "TTTableProducts.Products", False));
			
		QueryText = StrReplace(
			QueryText, 
			"&QueryTextVolumeM3", 
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("TTTableProducts.Package", "TTTableProducts.Products", False));
		
		Query.Text = QueryText;
		
		Query.SetParameter("Ref",FillingData);
		
		GoodsPlacement.Load(Query.Execute().Unload());
			
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Location);
		
		PlaceProducts("GoodsPlacement");
		
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Location);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsIssueNote") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,
			"Status, Warehouse, Premise, ShippingZone, DateOfShipment");
		
		If WarehousesServer.UseBinLocationWarehousing(DetailsOfFoundation.Warehouse, DetailsOfFoundation.Premise, DetailsOfFoundation.DateOfShipment) Then
		
			OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter;
			ReferenceOrder = FillingData; 
			
			FillPropertyValues(ThisObject,DetailsOfFoundation, "ShippingZone, Warehouse, Premise");
			
			FillInGoodsSelectionByOrder();
			
			SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
			ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Filter);
			
			PickUpProducts("GoodsFilter");
			
			ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Filter);
		Else
			
			MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" không sử dụng cơ chế lưu địa chỉ hàng hóa';
								|ru = 'На складе ""%Warehouse%"" не используется адресное хранение остатков';
								|en = 'Bin location system is disabled for warehouse ""%Warehouse%""'; fa = 'Bin location system is disabled for warehouse ""%Warehouse%""';
								|it = 'Nel magazzino ""%Warehouse%"" non viene utilizzato stoccaggio delle rimanenze codificato';
								|pl = 'W magazynie ""%Warehouse%"" nie jest używane adresowe przechowywanie ostatków';
								|tr = '""%Warehouse%"" ambarında, bakiyelerin depo konum takibi kullanılmıyor'");
			MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(DetailsOfFoundation.Warehouse, DetailsOfFoundation.Premise));
			Raise MessageText;
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsTransferNote") Then 
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,
			"Status, Warehouse, SenderWareroom, ReceivingWareroom, ShippingZone, ReceivingArea, DateOfShipment");
		
		If DetailsOfFoundation.Status = Enums.TransferNoteStatuses.ForPicking Then
			
			If WarehousesServer.UseBinLocationWarehousing(DetailsOfFoundation.Warehouse, DetailsOfFoundation.SenderWareroom, DetailsOfFoundation.DateOfShipment) Then
				
				OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter;
				ReferenceOrder = FillingData; 
				Premise = DetailsOfFoundation.SenderWareroom;
				
				FillPropertyValues(ThisObject,DetailsOfFoundation, "ShippingZone, Warehouse");
				
				FillInGoodsSelectionByOrder();
				
				SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
				ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Filter);
				
				PickUpProducts("GoodsFilter");
				
				ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Filter);
			Else
				
				MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" không sử dụng cơ chế lưu địa chỉ hàng hóa';
									|ru = 'На складе ""%Warehouse%"" не используется адресное хранение остатков';
									|en = 'Bin location system is disabled for warehouse ""%Warehouse%""'; fa = 'Bin location system is disabled for warehouse ""%Warehouse%""';
									|it = 'Nel magazzino ""%Warehouse%"" non viene utilizzato stoccaggio delle rimanenze codificato';
									|pl = 'W magazynie ""%Warehouse%"" nie jest używane adresowe przechowywanie ostatków';
									|tr = '""%Warehouse%"" ambarında, bakiyelerin depo konum takibi kullanılmıyor'");
				MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(DetailsOfFoundation.Warehouse, DetailsOfFoundation.SenderWareroom));
				Raise MessageText;
				
			EndIf;
			
		ElsIf DetailsOfFoundation.Status = Enums.TransferNoteStatuses.Accepted Then
			
			If WarehousesServer.UseBinLocationWarehousing(DetailsOfFoundation.Warehouse, DetailsOfFoundation.ReceivingWareroom, DetailsOfFoundation.DateOfShipment) Then
				OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location;
				Premise = DetailsOfFoundation.ReceivingWareroom;
				
				FillPropertyValues(ThisObject,DetailsOfFoundation, "ReceivingArea, Warehouse");
				
				Query = New Query;
				Query.Text =
				"SELECT
				|	GoodsTable.Products,
				|	GoodsTable.Characteristic,
				|	GoodsTable.Purpose,
				|	GoodsTable.Package,
				|	GoodsTable.Series AS Series,
				|	SUM(GoodsTable.Count) AS Count,
				|	SUM(GoodsTable.NumberOfPackages) AS NumberOfPackages
				|FROM
				|	Document.GoodsTransferNote.ShippedGoods AS GoodsTable
				|WHERE
				|	GoodsTable.Ref = &Ref
				|
				|GROUP BY
				|	GoodsTable.Package,
				|	GoodsTable.Products,
				|	GoodsTable.Purpose,
				|	GoodsTable.Series,
				|	GoodsTable.Characteristic
				|
				|ORDER BY
				|	GoodsTable.Products.Description,
				|	GoodsTable.Characteristic.Description";
				
				Query.SetParameter("Ref",FillingData);
				
				GoodsPlacement.Load(Query.Execute().Unload());
								
				SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
				ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Location);
				
				PlaceProducts("GoodsPlacement");
				
				ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Location);				
			Else
				
				MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" không sử dụng cơ chế lưu địa chỉ hàng hóa';
									|ru = 'На складе ""%Warehouse%"" не используется адресное хранение остатков';
									|en = 'Bin location system is disabled for warehouse ""%Warehouse%""'; fa = 'Bin location system is disabled for warehouse ""%Warehouse%""';
									|it = 'Nel magazzino ""%Warehouse%"" non viene utilizzato stoccaggio delle rimanenze codificato';
									|pl = 'W magazynie ""%Warehouse%"" nie jest używane adresowe przechowywanie ostatków';
									|tr = '""%Warehouse%"" ambarında, bakiyelerin depo konum takibi kullanılmıyor'");
				MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(DetailsOfFoundation.Warehouse, DetailsOfFoundation.ReceivingWareroom));
				Raise MessageText;
				
			EndIf;
			
		Else
			
			MessageText = NStr("vi = 'Có thể nhập nhiệm vụ lấy ra (xếp vào), khi chứng từ có
			|trạng thái ""Cần lấy ra"" hoặc ""Đã tiếp nhận""';
			|ru = 'Ввод заданий на отбор (размещение) товаров возможен, когда документ находится
			|статусах ""К отбору"" или ""Принят""';
			|en = 'You can generate tasks only from documents
			|with status ""Ready for picking"" or ""Accepted""'; fa = 'You can generate tasks only from documents
			|with status ""Ready for picking"" or ""Accepted""';
			|it = 'L''immissione degli incarichi per la selezione (collocamento) delle merci è possibile quando il documento si trova
			|negli stati ""Da selezionare"" o ""Accettato""';
			|pl = 'Wprowadzenie zadań doboru (rozmieszczenie) towarów jest możliwe, kiedy dokument znajduje się 
			| w statusach ""К отбору"" lub ""Принят""';
			|tr = 'Ürünlerin toplanması (yerleştirilmesi) için görevlerin girilmesi,
			|belge ""Toplamaya hazır"" veya ""Kabul edildi"" durumundayken mümkündür.'");
			Raise MessageText;
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsPickingPlacement") Then 
		
		// If there is an intra-warehouse movement, then we copy from PM the placement of the source to PM the Selection of the receiver
		// for the type of operation "Selection" of the source, we call an exception
		// the source must be in the status "Completed".
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,
			"Status, OperationKind, Warehouse, Premise, ShippingZone, ReceivingArea");
		
		If DetailsOfFoundation.OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
			MessageText = NStr("vi = 'Đối với dạng giao dịch %OperationKind%, không có tính năng nhập trên cơ sở điều chuyển nội bộ kho';
								|ru = 'Для вида операции %OperationKind% ввод на основании внутрискладского перемещения не предусмотрен.';
								|en = 'You cannot generate a document from an intra-warehouse transfer order with transaction type ""%OperationKind%"".'; fa = 'You cannot generate a document from an intra-warehouse transfer order with transaction type ""%OperationKind%"".';
								|it = 'Per il tipo di operazione %OperationKind% l''immissione in base al trasferimento all''interno del magazzino non è prevista.';
								|pl = 'Dla rodzaju operacji %OperationKind% wprowadzenie na podstawie wewnątrzmagazynowego przemieszczenia nie jest przewidziane.';
								|tr = '%OperationKind% işlem türü için ambar içi transfere dayalı giriş öngörülmemektedir.'");
			MessageText = StrReplace(MessageText,"%OperationKind%", DetailsOfFoundation.OperationKind);
			Raise MessageText;
		ElsIf DetailsOfFoundation.Status <> Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors
			And DetailsOfFoundation.Status <> Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
			MessageText = NStr("vi = 'Đối với trạng thái chứng từ %DocumentStatus%, không có tính năng nhập trên cơ sở điều chuyển nội bộ trong kho';
								|ru = 'Для статуса документа %DocumentStatus% ввод на основании внутрискладского перемещения не предусмотрен.';
								|en = 'You cannot generate an intra-warehouse transfer order from a document with status ""%DocumentStatus%"".'; fa = 'You cannot generate an intra-warehouse transfer order from a document with status ""%DocumentStatus%"".';
								|it = 'Per lo stato di documento %DocumentStatus% l''immissione in base al trasferimento all''interno del magazzino non è prevista.';
								|pl = 'Dla statusu dokumentu %DocumentStatus% wprowadzenie na podstawie wewnątrzmagazynowego przemieszczenia nie jest przewidziane.';
								|tr = '%DocumentStatus% belge durumu için ambar içi transfere dayalı giriş öngörülmemektedir.'");
			MessageText = StrReplace(MessageText,"%DocumentStatus%", DetailsOfFoundation.Status);
			Raise MessageText;
		Else
			
			OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move;
			
			FillPropertyValues(ThisObject, DetailsOfFoundation, "Warehouse, Premise");
			
			GoodsToBePlaced = Common.ObjectAttributeValue(FillingData, "GoodsPlacement").Unload(); // ValueTable
			For Each RowOfTables In GoodsToBePlaced Do
				
				NewRow = GoodsFilter.Add();
				
				FillPropertyValues(NewRow, RowOfTables,
					"Products, Characteristic, Purpose, Cell, Package, Series");
				
				NewRow.Count = RowOfTables.CountPlaced;
				NewRow.NumberOfPackages = RowOfTables.NumberOfPackagesPlaced;
				
			EndDo;
			
			SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
			
			ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Filter);
			
			PlaceProducts("GoodsFilter");
			
			ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Filter);
			ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject,SeriesSpecificationParameters.Location);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
		
		GoodsPlacement.Clear();
		
		ReceivingArea = Catalogs.StorageBins.EmptyRef();
		
	ElsIf OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		
		GoodsFilter.Clear();
		
		ReferenceOrder = Undefined;
		ShippingZone = Catalogs.StorageBins.EmptyRef();
		
	ElsIf OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
		
		ReferenceOrder	= Undefined;
		ReceivingArea		= Catalogs.StorageBins.EmptyRef();
		ShippingZone	= Catalogs.StorageBins.EmptyRef();
		
	EndIf;
	
	Completed2 = (Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors
				Or Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors);
	
	If ValueIsFilled(Ref) Then
		
		StatusBeforeRecording = Common.ObjectAttributeValue(Ref, "Status");
		
		If Status = Enums.StatusesOfGoodsPickingPlacement.InProgress
			And StatusBeforeRecording <> Enums.StatusesOfGoodsPickingPlacement.InProgress Then
			
			If Not ValueIsFilled(ExecutionStartDate) Then
				ExecutionStartDate = CurrentSessionDate();
			EndIf;
			
			If ValueIsFilled(ExecutionEndDate)
				And ExecutionStartDate > ExecutionEndDate Then
				
				ExecutionEndDate = ExecutionStartDate + 1;
				
			EndIf;
			
		ElsIf Completed2
			And (Not ValueIsFilled(StatusBeforeRecording)
				Or StatusBeforeRecording = Enums.StatusesOfGoodsPickingPlacement.Prepared2
				Or StatusBeforeRecording = Enums.StatusesOfGoodsPickingPlacement.InProgress) Then
			
			If Not ValueIsFilled(ExecutionStartDate) Then
				ExecutionStartDate = CurrentSessionDate();
			EndIf;
			
			ExecutionEndDate = CurrentSessionDate();
			
			If ExecutionStartDate > ExecutionEndDate Then
				ExecutionStartDate = ExecutionEndDate - 1;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.Filter);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.Location);
	
	WeightPlacement	= 0;
	VolumePutAway	= 0;
	
	For Each RowOfTables In GoodsPlacement Do
		
		If Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors Then
			
			RowOfTables.CountPlaced			= RowOfTables.Count;
			RowOfTables.NumberOfPackagesPlaced	= RowOfTables.NumberOfPackages;
			
		ElsIf Status = Enums.StatusesOfGoodsPickingPlacement.InProgress
			Or Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2 Then
			
			RowOfTables.CountPlaced			= 0;
			RowOfTables.NumberOfPackagesPlaced	= 0;
			
		EndIf;
		
		QuantityToBePlaced = ?(Completed2, RowOfTables.NumberOfPackagesPlaced, RowOfTables.NumberOfPackages);
		
		WeightPlacement	= WeightPlacement + RowOfTables.PackageWeight * QuantityToBePlaced;
		VolumePutAway	= VolumePutAway + RowOfTables.PackageVolume * QuantityToBePlaced;
		
		If RowOfTables.BatchesIndicationStatus = 0 Then
			RowOfTables.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
	EndDo;
	
	WeightFilter	= 0;
	VolumePick	= 0;
	
	For Each RowOfTables In GoodsFilter Do
		
		If Status = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors Then
			
			RowOfTables.CountPicked			= RowOfTables.Count;
			RowOfTables.NumberOfPackagesPicked	= RowOfTables.NumberOfPackages;
			
		ElsIf Status = Enums.StatusesOfGoodsPickingPlacement.InProgress
			Or Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2 Then
			
			RowOfTables.CountPicked			= 0;
			RowOfTables.NumberOfPackagesPicked	= 0;
			
		EndIf;
		
		QuantityToBeSelected = ?(Completed2, RowOfTables.NumberOfPackagesPicked, RowOfTables.NumberOfPackages);
		
		WeightFilter	= WeightFilter + RowOfTables.PackageWeight * QuantityToBeSelected;
		VolumePick	= VolumePick + RowOfTables.PackageVolume * QuantityToBeSelected;
		
		If RowOfTables.BatchesIndicationStatus = 0 Then
			RowOfTables.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	CheckCellLock(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WarehousesServer.ReflectStatesOfCellRecalculations(ThisObject.Ref, ThisObject.Status, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	CheckCellLock(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	ClearActualNumberOfWH();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	
	If AdditionalProperties.Property("CheckParameters") Then	
		CheckParameters = AdditionalProperties.CheckParameters;
		UnverifiableDetailsArray = CheckParameters.AttributesNotToCheck;
		For Each ArrRow In UnverifiableDetailsArray Do
			NotCheckedAttributeArray.Add(ArrRow);
		EndDo;
	Else
		If Not Posted
			And Status <> Enums.StatusesOfGoodsPickingPlacement.InProgress
			And Status <> Enums.StatusesOfGoodsPickingPlacement.Prepared2 Then
			
			MessageText = NStr("vi = 'Chứng từ phải được kết chuyển ban đầu ở trạng thái ""Đang làm việc"" hoặc ""Đã chuẩn bị""';
								|ru = 'Документ должен быть проведен сначала в статусе ""В работе"" или ""Подготовлено""';
								|en = 'First, you need to post the document with status ""In progress"" or ""Prepared""'; fa = 'First, you need to post the document with status ""In progress"" or ""Prepared""';
								|it = 'Il documento deve essere per prima registrato nello stato ""In esecuzione"" o ""Preparato""';
								|pl = 'Dokument należy najpierw zatwierdzić w statusie ""В работе"" lub ""Подготовлено""';
								|tr = 'Belge önce ""İşleniyor"" veya ""Hazırlanıyor"" durumunda kaydedilmelidir.'");
			
			CommonClientServer.MessageToUser(MessageText,ThisObject,"Status","Object",Cancel);
		EndIf;

		If OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move Then
			VerifyQuantityInBaseUnits(Cancel);	
		EndIf;
	EndIf;
	
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	If OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "GoodsFilter";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
		
		NotCheckedAttributeArray.Add("ReceivingArea");
		NotCheckedAttributeArray.Add("GoodsPlacement");
	ElsIf OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "GoodsPlacement";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
		
		NotCheckedAttributeArray.Add("ShippingZone");
		NotCheckedAttributeArray.Add("GoodsFilter");
		NotCheckedAttributeArray.Add("ReferenceOrder");
	ElsIf OperationKind = Enums.OperationKindsOfGoodsPlacementPicking.Move  Then
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "GoodsFilter";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "GoodsPlacement";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
		
		NotCheckedAttributeArray.Add("ReceivingArea");
		NotCheckedAttributeArray.Add("ShippingZone");
		NotCheckedAttributeArray.Add("ReferenceOrder");
	EndIf;
	
	If Not GetFunctionalOption("UseItemPackages") Then
		NotCheckedAttributeArray.Add("GoodsPlacement.Package");
		NotCheckedAttributeArray.Add("GoodsFilter.Package");
		MessageText = NStr("vi = 'Trong tùy chỉnh chương trình chưa bật sử dụng đóng gói mặt hàng, 
		|do đó không thể lập chứng từ theo kho có cất giữ số dư theo địa chỉ. Hãy liên hệ với người quản trị';
		|ru = 'В настройках программы не включено использование упаковок номенклатуры, 
		|поэтому нельзя оформить документ по складу с адресным хранением остатков. Обратитесь к администратору';
		|en = 'Packaging options are disabled in the application settings. To create a document that uses bin locations, you need to enable packaging options.
		|Please contact the administrator'; fa = 'Packaging options are disabled in the application settings. To create a document that uses bin locations, you need to enable packaging options.
		|Please contact the administrator';
		|it = 'Le impostazioni del programma non includono l''uso di imballaggio degli articoli, 
		|pertanto è impossibile formalizzare il documento per magazzino con il sistema di stoccaggio giacenze codificato. Contattare amministratore';
		|pl = 'W ustawieniach programu nie jest włączone użycie paczek wykazu towaru,
		|dlatego niemożliwe jest sporządzenie dokumentu dla magazynu z przechowywaniem pozostałości. Skontaktuj się z administratorem';
		|tr = 'Uygulama ayarlarında ürün paketleme kullanımı etkin değildir,
		|bu nedenle depo konum takibi olan bir ambar için belge düzenleyemezsiniz. Yönetici ile iletişime geçin'");
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
	CheckParameters.OtherPresentationPackagingUnits = NStr("vi = 'Đơn vị tính';
															|ru = 'Ед. изм.';
															|en = 'Unit'; fa = 'واحد';
															|it = 'Unità di misura';
															|pl = 'J. m.';
															|tr = 'Ölçü birimi.'");
	CheckParameters.TSName = "GoodsFilter";
	ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
	CheckParameters.TSName = "GoodsPlacement";
	ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
	
	ParametersForCheckingIndicationOfMultiTurnContainer = ReusablePackageServer.ParametersForCheckingIndicationOfMultiTurnContainer();
	ParametersForCheckingIndicationOfMultiTurnContainer.TSName = "GoodsFilter";
	ReusablePackageServer.CheckIndicationOfMultiTurnContainer(ThisObject, ParametersForCheckingIndicationOfMultiTurnContainer, Cancel);
	ParametersForCheckingIndicationOfMultiTurnContainer.TSName = "GoodsPlacement";
	ReusablePackageServer.CheckIndicationOfMultiTurnContainer(ThisObject, ParametersForCheckingIndicationOfMultiTurnContainer, Cancel);
	
	WarehousesServer.CheckUseOfCellsAccordingToSeparationRules(ThisObject, Cancel, "GoodsPlacement");
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsPickingPlacement);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.Filter);
	ParametersArray.Add(SeriesSpecificationParameters.Location);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "GoodsFilter";
	If Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		CheckParameters.FieldNamesWithSuffix.Insert("Count", "CountPicked");
		CheckParameters.FieldNamesWithSuffix.Insert("NumberOfPackages", "NumberOfPackagesPicked");
	EndIf;
	CheckParameters.CheckPossibilityOfRounding = False;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel,CheckParameters);

	CheckParameters.TSName = "GoodsPlacement";
	If Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		CheckParameters.FieldNamesWithSuffix.Insert("Count", "CountPlaced");
		CheckParameters.FieldNamesWithSuffix.Insert("NumberOfPackages", "NumberOfPackagesPlaced");
	EndIf;
	CheckParameters.CheckPossibilityOfRounding = False;
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel,CheckParameters);
	
	If OperationKind <> Enums.OperationKindsOfGoodsPlacementPicking.Location Then
		WarehousesServer.CheckWarehouseOrder(Warehouse, Date, "OnShipment", Cancel);
	EndIf;
	
	If OperationKind <> Enums.OperationKindsOfGoodsPlacementPicking.Filter Then
		WarehousesServer.CheckWarehouseOrder(Warehouse, Date, "OnReceipt", Cancel);
	EndIf;
	
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInGoodsSelectionByOrder() Export 
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsForPickingBalance.Products AS Products,
	|	GoodsForPickingBalance.Characteristic AS Characteristic,
	|	GoodsForPickingBalance.Purpose AS Purpose,
	|	GoodsForPickingBalance.Series AS Series,
	|	GoodsForPickingBalance.ForPickingBalance AS ForPickingBalance,
	|	GoodsForPickingBalance.BeingPickedBalance AS BeingPickedBalance,
	|	GoodsForPickingBalance.PickedBalance AS PickedBalance,
	|	GoodsForPickingBalance.CargoItem AS CargoItem
	|INTO GoodsForPickingBalance
	|FROM
	|	AccumulationRegister.GoodsForPicking.Balance(, ReferenceOrder = &ReferenceOrder) AS GoodsForPickingBalance
	|;	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForPickingBalance.Products,
	|	GoodsForPickingBalance.Characteristic,
	|	GoodsForPickingBalance.Purpose,
	|	GoodsForPickingBalance.Series,
	|	GoodsForPickingBalance.CargoItem AS Package,
	|	SUM(GoodsForPickingBalance.ForPickingBalance) - SUM(GoodsForPickingBalance.BeingPickedBalance) - SUM(GoodsForPickingBalance.PickedBalance) AS Count,
	|	SUM(GoodsForPickingBalance.ForPickingBalance) - SUM(GoodsForPickingBalance.BeingPickedBalance) - SUM(GoodsForPickingBalance.PickedBalance) AS NumberOfPackages
	|FROM
	|	GoodsForPickingBalance AS GoodsForPickingBalance
	|
	|GROUP BY
	|	GoodsForPickingBalance.Products,
	|	GoodsForPickingBalance.Characteristic,
	|	GoodsForPickingBalance.Purpose,
	|	GoodsForPickingBalance.Series,
	|	GoodsForPickingBalance.CargoItem
	|
	|HAVING
	|	SUM(GoodsForPickingBalance.ForPickingBalance) - SUM(GoodsForPickingBalance.BeingPickedBalance) - SUM(GoodsForPickingBalance.PickedBalance) > 0";
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	GoodsFilter.Load(Query.Execute().Unload());
	
EndProcedure

Procedure FillQuantityCompleted(TSName) Export
	
	If StrFind(TSName,"Filter") <> 0 Then
		NameQuantity 			= "CountPicked";
		NameNumberOfPackages 	= "NumberOfPackagesPicked";
	Else
		NameQuantity 			= "CountPlaced";
		NameNumberOfPackages 	= "NumberOfPackagesPlaced";
	EndIf;
	
	For Each RowOfTables In ThisObject[TSName] Do
		
		RowOfTables[NameQuantity] 			= RowOfTables.Count;
		RowOfTables[NameNumberOfPackages] 	= RowOfTables.NumberOfPackages;
		
	EndDo;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Date					= CurrentSessionDate();
	Status					= Metadata().Attributes.Status.FillValue;
	ExecutionStartDate	= Date(1, 1, 1);
	ExecutionEndDate	= Date(1, 1, 1);
	Warehouse					= SettingsValueCached.GetDefaultWarehouse(Warehouse);
	EmployeeResponsible			= Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInVerificationParameters(Source)
	
	CheckParameters = New Structure;	
	AttributesNotToCheck = New Array;
	CheckParameters.Insert("AttributesNotToCheck",AttributesNotToCheck);
	
	CheckParameters.AttributesNotToCheck.Add("ReferenceOrder");
	CheckParameters.AttributesNotToCheck.Add("ShippingZone");
	CheckParameters.AttributesNotToCheck.Add("ReceivingArea");
	
	If Source = "GoodsPlacement" Then
		
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Cell");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Products");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Characteristic");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Purpose");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Package");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Count");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.NumberOfPackages");
		
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.Cell");
		
	ElsIf Source = "GoodsFilter" Then
		
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement");
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.Cell");
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.Products");
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.Characteristic");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Purpose");
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.Package");
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.Count");
		CheckParameters.AttributesNotToCheck.Add("GoodsPlacement.NumberOfPackages");
		
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Cell");
		CheckParameters.AttributesNotToCheck.Add("GoodsFilter.Package");
	EndIf;
	
	AdditionalProperties.Insert("CheckParameters",CheckParameters);

EndProcedure

Procedure VerifyQuantityInBaseUnits(Cancel)
	
	If GoodsFilter.Count() = 0
		Or GoodsPlacement.Count() = 0 Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	CheckTable = New ValueTable;
	CheckTable.Columns.Add("Products");
	CheckTable.Columns.Add("Characteristic");
	CheckTable.Columns.Add("Purpose");
	CheckTable.Columns.Add("Series");
	CheckTable.Columns.Add("Count");
	CheckTable.Columns.Add("QuantityCompleted");
	
	TableSelectedPlaced = New ValueTable;
	TableSelectedPlaced.Columns.Add("Products");
	TableSelectedPlaced.Columns.Add("Characteristic");
	TableSelectedPlaced.Columns.Add("Purpose");
	TableSelectedPlaced.Columns.Add("Series");
	TableSelectedPlaced.Columns.Add("CountPicked");
	TableSelectedPlaced.Columns.Add("CountPlaced");
	
	For Each RowOfTables In GoodsPlacement Do
		
		// Add an entry to the validation table.
		NewRow = CheckTable.Add();
		
		FillPropertyValues(NewRow,RowOfTables);
		NewRow.Count = RowOfTables.Count;
		NewRow.QuantityCompleted = RowOfTables.CountPlaced;
		
		// Add an entry to the "Selected = Placed" check table
		NewRow = TableSelectedPlaced.Add();
		
		FillPropertyValues(NewRow,RowOfTables);
		NewRow.CountPicked = 0;
		NewRow.CountPlaced = RowOfTables.CountPlaced;
		
	EndDo;
	
	For Each RowOfTables In GoodsFilter Do
		
		// Add an entry to the validation table.
		NewRow = CheckTable.Add();
		
		FillPropertyValues(NewRow,RowOfTables);
		NewRow.Count = -RowOfTables.Count;
		NewRow.QuantityCompleted = -RowOfTables.CountPicked;
		
		// Add an entry to the "Selected = Placed" check table
		NewRow = TableSelectedPlaced.Add();
		
		FillPropertyValues(NewRow,RowOfTables);
		NewRow.CountPicked = RowOfTables.CountPicked;
		NewRow.CountPlaced = 0;
		
	EndDo;
	
	CheckTable.GroupBy("Products, Characteristic, Purpose, Series", "Count, QuantityCompleted");
	TableSelectedPlaced.GroupBy("Products, Characteristic, Purpose, Series", "CountPicked, CountPlaced");
	
	If Status = Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
		
		// Check that the placed quantity is equal to the selected one.
		
		For Each RowOfTables In TableSelectedPlaced Do
			
			// If the item is not filled in, there will still be a validation error.
			If Not ValueIsFilled(RowOfTables.Products) Then
				Continue;
			EndIf;
			
			Count = 0;
			
			If RowOfTables.CountPicked > RowOfTables.CountPlaced Then
				MessageText = NStr("vi = 'Số lượng mặt hàng lấy ra ""%ProductPresentation%"" lớn hơn số lượng được phân bổ với %Count% đơn vị lưu kho';
									|ru = 'Отобранное количество номенклатуры ""%ProductPresentation%"" больше, чем размещенное на %Count% единиц хранения';
									|en = 'Number of picked item ""%ProductPresentation%"" exceeds the number of the placed ones by %Count% stock UOM'; fa = 'Number of picked item ""%ProductPresentation%"" exceeds the number of the placed ones by %Count% stock UOM';
									|it = 'La quantità selezionata della nomenclatura ""%ProductPresentation%"" è superiore di quella collocata di %Count% unità di stoccaggio';
									|pl = 'Wybrana ilość produktów ""%ProductPresentation%"" jest większa, niż rozmieszczenie na %Count% miejsc przechowywania';
									|tr = '""%ProductPresentation%"" ürün gamının seçilen miktarı, %Count% stok ölçü birimlerine yerleştirilen miktardan fazla'");
				Count = RowOfTables.CountPicked - RowOfTables.CountPlaced;
			ElsIf RowOfTables.CountPicked < RowOfTables.CountPlaced Then
				MessageText = NStr("vi = 'Số lượng mặt hàng lấy ra ""%ProductPresentation%"" nhỏ hơn số lượng phân bổ với %Count% đơn vị lưu kho';
									|ru = 'Отобранное количество номенклатуры ""%ProductPresentation%"" меньше, чем размещенное на %Count% единиц хранения';
									|en = 'Number of picked item ""%ProductPresentation%"" is less than the number of the placed ones by %Count% stock UOM'; fa = 'Number of picked item ""%ProductPresentation%"" is less than the number of the placed ones by %Count% stock UOM';
									|it = 'La quantità selezionata della nomenclatura ""%ProductPresentation%"" è inferiore di quella collocata di %Count% unità di stoccaggio';
									|pl = 'Dobrana ilość produktów ""%ProductPresentation%"" jest mniejsza niż rozmieszczenie  %Count% jednostek przechowywania';
									|tr = '""%ProductPresentation%"" ürün gamının seçilen miktarı, %Count% stok ölçü birimlerine yerleştirilen miktardan az'");
				Count = RowOfTables.CountPlaced - RowOfTables.CountPicked;
			EndIf;
			
			If Count <> 0 Then
				
				ProductPresentation = ProductsClientServer.ProductPresentation(RowOfTables.Products,
																								RowOfTables.Characteristic,
																								,
																								RowOfTables.Series,
																								RowOfTables.Purpose);
				
				MessageText = StrReplace(MessageText,"%ProductPresentation%", ProductPresentation);
				MessageText = StrReplace(MessageText,"%Count%", Count);
				
				CommonClientServer.MessageToUser(MessageText,,,,Cancel);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each RowOfTables In CheckTable Do
			
			// If the item is not filled in, there will still be a validation error.
			If Not ValueIsFilled(RowOfTables.Products) Then
				Continue;
			EndIf;
			
			Count = 0;
			
			If RowOfTables.Count > 0 Then
				MessageText = NStr("vi = 'Số lượng được lên kế hoạch để lựa chọn mục ""%ProductPresentation%"" nhỏ hơn số lượng được đặt bởi %Count% ';
									|ru = 'Запланированное к отбору количество номенклатуры ""%ProductPresentation%"" меньше, чем размещенное на %Count% единиц хранения';
									|en = 'Quantity of the ""%ProductPresentation%"" items planned for picking is less than the placed quantity by %Count% stock UOM'; fa = 'Quantity of the ""%ProductPresentation%"" items planned for picking is less than the placed quantity by %Count% stock UOM';
									|it = 'La quantità della nomenclatura prevista per la selezione ""%ProductPresentation%"" è inferiore di quella collocata di %Count% unità di stoccaggio';
									|pl = 'Zaplanowana do doboru ilość produktów ""%ProductPresentation%"" jest mniejsza niż rozmieszczono na %Count% jednostek przechowywania';
									|tr = 'Filtre için planlanan ürün gamı ""%ProductPresentation%"" miktarı, %Count% stok ölçü birimlerine yerleştirilen miktardan az'");
				Count = RowOfTables.Count;
			ElsIf RowOfTables.Count < 0 Then
				MessageText = NStr("vi = 'Số lượng được lên kế hoạch để lựa chọn mục ""%ProductPresentation%"" nhiều hơn số lượng được đặt bởi %Count%';
									|ru = 'Запланированное к отбору количество номенклатуры ""%ProductPresentation%"" больше, чем размещенное на %Count% единиц хранения';
									|en = 'Quantity of the ""%ProductPresentation%"" items planned for picking is greater than the placed quantity by %Count% stock UOM'; fa = 'Quantity of the ""%ProductPresentation%"" items planned for picking is greater than the placed quantity by %Count% stock UOM';
									|it = 'La quantità della nomenclatura prevista per la selezione ""%ProductPresentation%"" è superiore di quella collocata di %Count% unità di stoccaggio';
									|pl = 'Zaplanowana do doboru ilość produktów ""%ProductPresentation%"" jest większa, niż rozmieszczono na %Count% jednostek przechowywania';
									|tr = 'Filtre için planlanan ürün gamı ""%ProductPresentation%"" miktarı, %Count% stok ölçü birimlerine yerleştirilen miktardan fazla'");
				Count = - RowOfTables.Count;
			EndIf;
			
			If Count <> 0 Then
				
				ProductPresentation = ProductsClientServer.ProductPresentation(
					RowOfTables.Products,
					RowOfTables.Characteristic,
					,
					RowOfTables.Series, 
					RowOfTables.Purpose);
				
				MessageText = StrReplace(MessageText,"%ProductPresentation%", ProductPresentation);
				MessageText = StrReplace(MessageText,"%Count%", Count);
				
				CommonClientServer.MessageToUser(MessageText,,,,Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckCellLock(Cancel)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CellTable.Cell AS Cell
	|FROM
	|	(SELECT
	|		SelectionProductPlacementProductsSelection.Cell AS Cell
	|	FROM
	|		Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
	|	WHERE
	|		SelectionProductPlacementProductsSelection.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SelectionProductPlacementProductsPlacement.Cell
	|	FROM
	|		Document.GoodsPickingPlacement.GoodsPlacement AS SelectionProductPlacementProductsPlacement
	|	WHERE
	|		SelectionProductPlacementProductsPlacement.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|				THEN GoodsPickingPlacement.ReceivingArea
	|			WHEN GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
	|				THEN GoodsPickingPlacement.ShippingZone
	|		END
	|	FROM
	|		Document.GoodsPickingPlacement AS GoodsPickingPlacement
	|	WHERE
	|		GoodsPickingPlacement.Ref = &Ref
	|		AND (GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|				OR GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter))) AS CellTable
	|
	|GROUP BY
	|	CellTable.Cell";
	
	Query.SetParameter("Ref", Ref);
	
	CellTable = Query.Execute();
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.StorageBinsLocks");
	LockItem.Mode          = DataLockMode.Shared;
	LockItem.DataSource = CellTable;
	LockItem.UseFromDataSource("Cell", "Cell");
	
	Block.Lock();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BlockedBins.Cell AS Cell,
	|	BlockedBins.LockType
	|FROM
	|	(SELECT
	|		StorageBinsLocks.Cell AS Cell,
	|		StorageBinsLocks.LockType AS LockType
	|	FROM
	|		InformationRegister.StorageBinsLocks AS StorageBinsLocks
	|			INNER JOIN Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
	|			ON StorageBinsLocks.Cell = SelectionProductPlacementProductsSelection.Cell
	|	WHERE
	|		SelectionProductPlacementProductsSelection.Ref = &Ref
	|		AND (StorageBinsLocks.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Full)
	|				OR StorageBinsLocks.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Filter))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		StorageBinsLocks.Cell,
	|		StorageBinsLocks.LockType
	|	FROM
	|		InformationRegister.StorageBinsLocks AS StorageBinsLocks
	|			INNER JOIN Document.GoodsPickingPlacement.GoodsPlacement AS SelectionProductPlacementProductsPlacement
	|			ON StorageBinsLocks.Cell = SelectionProductPlacementProductsPlacement.Cell
	|	WHERE
	|		SelectionProductPlacementProductsPlacement.Ref = &Ref
	|		AND (StorageBinsLocks.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Full)
	|				OR StorageBinsLocks.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Location))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
	|				THEN GoodsPickingPlacement.ShippingZone
	|			ELSE GoodsPickingPlacement.ReceivingArea
	|		END,
	|		StorageBinsLocks.LockType
	|	FROM
	|		Document.GoodsPickingPlacement AS GoodsPickingPlacement
	|			INNER JOIN InformationRegister.StorageBinsLocks AS StorageBinsLocks
	|			ON (CASE
	|					WHEN GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
	|						THEN GoodsPickingPlacement.ShippingZone = StorageBinsLocks.Cell
	|					WHEN GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|						THEN GoodsPickingPlacement.ReceivingArea = StorageBinsLocks.Cell
	|				END)
	|	WHERE
	|		GoodsPickingPlacement.Ref = &Ref
	|		AND (GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Location)
	|				OR GoodsPickingPlacement.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter))) AS BlockedBins
	|
	|GROUP BY
	|	BlockedBins.Cell,
	|	BlockedBins.LockType
	|
	|ORDER BY
	|	Cell";
	
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		MessageText = NStr("vi = 'Ô hàng %Cell% đã bị phong tỏa: kiểu phong tỏa ""%LockType%""';
							|ru = 'Ячейка %Cell% заблокирована: тип блокировки ""%LockType%""';
							|en = 'Storage bin %Cell% is blocked: block type ""%LockType%""'; fa = 'Storage bin %Cell% is blocked: block type ""%LockType%""';
							|it = 'Cella %Cell% è bloccata: tipo di blocco ""%LockType%""';
							|pl = 'Komórka %Cell% jest zablokowana: typ blokowania ""%LockType%""';
							|tr = '%Cell% hücresi kilitli: kilit türü ""%LockType%""'");
		MessageText = StrReplace(MessageText, "%Cell%", Selection.Cell);
		MessageText = StrReplace(MessageText, "%LockType%", Selection.LockType);
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndDo;
	
EndProcedure

Procedure ClearActualNumberOfWH()
	
	For Each TSRow In GoodsFilter Do
		TSRow.CountPicked 		= 0;
		TSRow.NumberOfPackagesPicked = 0;
	EndDo;
	
	For Each TSRow In GoodsPlacement Do
		TSRow.CountPlaced 		 = 0;
		TSRow.NumberOfPackagesPlaced = 0;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf