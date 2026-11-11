#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse,Premise,DateOfShipment) Then
		NotCheckedAttributeArray.Add("Goods.Package");
		UnitField = "Package";
	Else
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel);
		UnitField = "UnitOfMeasure";
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
	
	For Each RowOfTables In Goods Do
		If RowOfTables.DoNotShip = 1
			And RowOfTables.NumberOfPackages = 0 Then
		
			MessageText = NStr("vi = 'Chưa điền số lượng tại dòng chưa giao số %LineNumber%.';
								|ru = 'Не заполнено количество в неотгружаемой строке номер %LineNumber%.';
								|en = 'Quantity in unshipped line %LineNumber% is not filled in.'; fa = 'Quantity in unshipped line %LineNumber% is not filled in.';
								|it = 'Non è compilata la quantità nella riga non soggetta alla spedizione numero %LineNumber%.';
								|pl = 'Nie została wypełniona ilość w nie wysyłanym wierszu numer %LineNumber%.';
								|tr = 'Sevkiyat dışı satır numarasında miktar doldurulmadı %LineNumber%.'");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfTables.LineNumber);
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "NumberOfPackages");
			
			CommonClientServer.MessageToUser(MessageText,,Field,"Object",Cancel);
			
		EndIf;
	
		If RowOfTables.Count = 0 
			And RowOfTables.NumberOfPackages <> 0 Then
			
			MessageText = NStr("vi = 'Đã phát hiện số lượng bằng 0 khi tính lại theo đơn vị lưu kho tại dòng %LineNumber% trong danh sách ""%PresentationOfTS%""';
								|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %LineNumber% списка ""%PresentationOfTS%""';
								|en = 'Zero quantity is detected when converted to storage unit in line %LineNumber% of list ""%PresentationOfTS%""'; fa = 'Zero quantity is detected when converted to storage unit in line %LineNumber% of list ""%PresentationOfTS%""';
								|it = 'È stata rilevata la quantità pari a zero nel corso di ricalcolo in unità di stoccaggio nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
								|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania w wierszu %LineNumber% listy ""%PresentationOfTS%""';
								|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında stok ölçü birimine dönüştürülürken sıfır miktar bulundu'");
			MessageText = StrReplace(MessageText, "%LineNumber%", String(RowOfTables.LineNumber));
			MessageText = StrReplace(MessageText, "%PresentationOfTS%", NStr("vi = 'Hàng hóa';
																			|ru = 'Товары';
																			|en = 'Goods'; fa = 'کالاها';
																			|it = 'Merci';
																			|pl = 'Wiersze pozycji';
																			|tr = 'Ürünler'"));
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "NumberOfPackages");
			
			CommonClientServer.MessageToUser(MessageText,,Field,"Object",Cancel);
			
		EndIf;
		
		If RowOfTables.IssueStatus = 4 Then
			
			If RowOfTables.NumberOfPackagesInDocument > 0 Then
				MessageText = NStr("vi = 'Đã lấy ra lớn hơn yêu cầu trong phiếu. Cần đánh dấu %NumberSelectedMore% %UnitOfMeasure% là không thể giao hàng.';
									|ru = 'Отобрано на больше, чем требуется по ордеру. Необходимо для %NumberSelectedMore% %UnitOfMeasure% отметить, что это количество не нужно отгружать.';
									|en = 'Number of the picked ones exceeds the required amount according to the note. Note for %NumberSelectedMore% %UnitOfMeasure% that this quantity should not be shipped.'; fa = 'Number of the picked ones exceeds the required amount according to the note. Note for %NumberSelectedMore% %UnitOfMeasure% that this quantity should not be shipped.';
									|it = 'Selezionato più del richiesto per il mandato. È necessario per %NumberSelectedMore% %UnitOfMeasure% specificare che questa quantità non deve essere spedita.';
									|pl = 'Dobrano więcej, niż wymaga tego zlecenie. Należy dla %NumberSelectedMore% %UnitOfMeasure% zaznaczyć, że tę ilość nie trzeba wysyłać.';
									|tr = 'Siparişin gerektirdiğinden daha fazlası için toplanmış. %NumberSelectedMore% %UnitOfMeasure% için bu miktarın gönderilmesi gerekmediğini işaretle.'");
				
				MessageText = StrReplace(MessageText,"%NumberSelectedMore%", RowOfTables.NumberOfPackagesAmount - RowOfTables.NumberOfPackagesInDocument);  
				MessageText = StrReplace(MessageText,"%UnitOfMeasure%", RowOfTables[UnitField]);  
			Else
				If RowOfTables.NumberOfPackagesAmount > 0 Then
					MessageText = NStr("vi = 'Trong phiếu không có hàng hóa như vậy. Cần đánh dấu là không cần giao dòng này.';
										|ru = 'В ордере нет такого товара. Необходимо отметить, что эту строку не нужно отгружать.';
										|en = 'This product is not found in the note. Specify that this line should not be shipped.'; fa = 'This product is not found in the note. Specify that this line should not be shipped.';
										|it = 'Nel mandato non esiste questo prodotto. È necessario specificare che questa riga non deve essere spedita.';
										|pl = 'W zleceniu nie ma takiego towaru. Należy zaznaczyć, że ten wiersz nie trzeba wysyłać.';
										|tr = 'Siparişte böyle bir ürün yok. Bu hattın sevk edilmesi gerekmediğine dikkat edilmelidir.'");
				Else
					MessageText = NStr("vi = 'Trong phiếu không có hàng hóa như vậy. Cần điền số lượng và đánh dấu là không cần giao dòng này.';
										|ru = 'В ордере нет такого товара. Необходимо заполнить количество и отметить, что эту строку не нужно отгружать.';
										|en = 'This product is not found in the note. Fill in the quantity and specify that this line should not be shipped.'; fa = 'This product is not found in the note. Fill in the quantity and specify that this line should not be shipped.';
										|it = 'Nel mandato non esiste questo prodotto. È necessario compilare la quantità e specificare che questa riga non deve essere spedita.';
										|pl = 'W zleceniu nie ma takiego towaru. Należy wypełnić ilość i zaznaczyć, że ten wiersz nie trzeba wysyłać.';
										|tr = 'Siparişte böyle bir ürün yok. Miktarı doldurmalı ve bu satırın sevk edilmesi gerekmediğine dikkat edilmelidir.'");
				EndIf;
			EndIf;
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "IssueStatus");
			
			CommonClientServer.MessageToUser(MessageText,,Field,"Object",Cancel);
		EndIf;
		
	EndDo;

	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, DataProcessors.GoodsQuantityCheckInDocument),
		Cancel,
		NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

#EndRegion

#Region Private

Function FinishCheck(FieldsToConsider, TransferResultToOrder = True, ThisIsMRMCheck = False) Export
	
	// 1. We form a table based on the document data.
	// - if packages are taken into account, then by packages, otherwise in basic
	// - we take into account the series, if these are not the series that are indicated upon selection
	// - we ignore unloaded lines - we will always take them from processing
	// 2. We form a table based on the processing data.
	// - if packages are taken into account, then by packages, otherwise in basic
	// - we take into account the series, if these are not the series that are indicated upon selection
	// 3. Compare the sum of the lines being loaded with the document - we get a table of shortages
	// 4. We separate all unloaded lines
	// - for surpluses (they will then need to be used to make a document of the verification result and they need to be transferred to the document)
	// - just unloaded (they just need to be transferred to the document)
	// 5. If there are no surpluses and shortages, then we check the discrepancies by series (upon selection, taking into account the balances) - for
	// such series, you need to form a document of the verification result.
	
	Query = New Query;
	Query.SetParameter("Ref",WarehouseDocument);
	Query.SetParameter("GoodsFromProcessing",Goods.Unload());
	Query.SetParameter("PackingList_", FieldsToConsider.PackingList_);
	Query.SetParameter("ConsiderSeries", FieldsToConsider.ConsiderSeries);
	Query.SetParameter("SeriesStatusesThatAreNotTakenIntoAccount", FieldsToConsider.SeriesStatusesThatAreNotTakenIntoAccount);
	
	Query.SetParameter("AcrossTS",True);
	Query.SetParameter("ThisIsRemoval",False);
	Query.SetParameter("LineNumber",Undefined);
	Query.SetParameter("Products",Undefined);
	Query.SetParameter("Characteristic",Undefined);
	Query.SetParameter("Purpose",Undefined);
	Query.SetParameter("Package",Undefined);
	Query.SetParameter("Series",Undefined);
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextTemporaryDocumentAndProcessingTables();
	Query.ExecuteBatch();
	
	Query.Text =
	"SELECT
	|	ProductsFromOrder.Products AS Products,
	|	ProductsFromOrder.Characteristic AS Characteristic,
	|	ProductsFromOrder.Purpose AS Purpose,
	|	ProductsFromOrder.Series AS Series,
	|	0 AS QuantityToShip,
	|	0 AS NumberOfPackagesToShip,
	|	ProductsFromOrder.Count AS QuantityOfGoodsInDocument,
	|	ProductsFromOrder.NumberOfPackages AS NumberOfPackagesInDocument,
	|	CAST(ProductsFromOrder.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
	|INTO ProductsForInspection
	|FROM
	|	ProductsFromOrder AS ProductsFromOrder
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsFromProcessing.Products,
	|	GoodsFromProcessing.Characteristic,
	|	GoodsFromProcessing.Purpose,
	|	GoodsFromProcessing.Series,
	|	GoodsFromProcessing.Count,
	|	GoodsFromProcessing.NumberOfPackages,
	|	0,
	|	0,
	|	CAST(GoodsFromProcessing.Package AS Catalog.PackagesAndUnitsOfMeasure)
	|FROM
	|	GoodsFromProcessing AS GoodsFromProcessing
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UnassembledGoods.Products AS Products,
	|	UnassembledGoods.Characteristic AS Characteristic,
	|	UnassembledGoods.Purpose AS Purpose,
	|	UnassembledGoods.Series AS Series,
	|	UnassembledGoods.Package AS Package,
	|	SUM(CASE
	|			WHEN ISNULL(UnassembledGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|				THEN (UnassembledGoods.NumberOfPackagesInDocument - UnassembledGoods.NumberOfPackagesToShip) / UnassembledGoods.Package.NumberOfPackages
	|			ELSE UnassembledGoods.QuantityOfGoodsInDocument - UnassembledGoods.QuantityToShip
	|		END) AS QuantityShortage,
	|	SUM(CASE
	|			WHEN ISNULL(UnassembledGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|				THEN UnassembledGoods.NumberOfPackagesToShip / UnassembledGoods.Package.NumberOfPackages
	|			ELSE UnassembledGoods.QuantityToShip
	|		END) AS QuantityToShip,
	|	SUM(CASE
	|			WHEN ISNULL(UnassembledGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|				THEN UnassembledGoods.NumberOfPackagesInDocument / UnassembledGoods.Package.NumberOfPackages
	|			ELSE UnassembledGoods.QuantityOfGoodsInDocument
	|		END) AS QuantityOfGoodsInDocument,
	|	SUM(UnassembledGoods.NumberOfPackagesInDocument - UnassembledGoods.NumberOfPackagesToShip) AS NumberOfPackagesShortage,
	|	SUM(UnassembledGoods.NumberOfPackagesToShip) AS NumberOfPackagesToShip,
	|	SUM(UnassembledGoods.NumberOfPackagesInDocument) AS NumberOfPackagesInDocument,
	|	CASE
	|		WHEN Goods.UnitOfMeasure.MeasuredValueType IN (&TypesOfMeasuredQuantities)
	|			THEN CASE
	|					WHEN SUM(UnassembledGoods.QuantityToShip) >= SUM(UnassembledGoods.QuantityOfGoodsInDocument) - &AllowableVariance * SUM(UnassembledGoods.QuantityOfGoodsInDocument) / 100
	|						THEN FALSE
	|					ELSE TRUE
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(UnassembledGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|							AND SUM(UnassembledGoods.NumberOfPackagesInDocument - UnassembledGoods.NumberOfPackagesToShip) > 0
	|						OR SUM(UnassembledGoods.QuantityOfGoodsInDocument - UnassembledGoods.QuantityToShip) > 0
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS IsShortage
	|FROM
	|	ProductsForInspection AS UnassembledGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON UnassembledGoods.Products = Goods.Ref
	|
	|GROUP BY
	|	UnassembledGoods.Products,
	|	Goods.UnitOfMeasure.MeasuredValueType,
	|	UnassembledGoods.Characteristic,
	|	UnassembledGoods.Purpose,
	|	UnassembledGoods.Series,
	|	UnassembledGoods.Package,
	|	CASE
	|		WHEN ISNULL(UnassembledGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN UNDEFINED
	|		ELSE UnassembledGoods.Package
	|	END,
	|	UnassembledGoods.Package.PackageType
	|
	|HAVING
	|	(SUM(UnassembledGoods.QuantityOfGoodsInDocument - UnassembledGoods.QuantityToShip) > 0
	|		OR SUM(UnassembledGoods.NumberOfPackagesInDocument - UnassembledGoods.NumberOfPackagesToShip) > 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(GoodsFromProcessing.Products AS Catalog.Products) AS Products,
	|	GoodsFromProcessing.Characteristic AS Characteristic,
	|	CAST(GoodsFromProcessing.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	GoodsFromProcessing.Purpose AS Purpose,
	|	GoodsFromProcessing.Series AS Series,
	|	GoodsFromProcessing.Count AS Count,
	|	GoodsFromProcessing.NumberOfPackages AS NumberOfPackages,
	|	GoodsFromProcessing.QuantityOfGoodsInDocument AS QuantityOfGoodsInDocument,
	|	GoodsFromProcessing.NumberOfPackagesInDocument AS NumberOfPackagesInDocument
	|INTO ProductsFromProcessingForRequest
	|FROM
	|	&GoodsFromProcessing AS GoodsFromProcessing
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NotShippedGoods.Products AS Products,
	|	NotShippedGoods.Characteristic AS Characteristic,
	|	NotShippedGoods.Package AS Package,
	|	NotShippedGoods.Purpose AS Purpose,
	|	NotShippedGoods.Series AS Series,
	|	SUM(NotShippedGoods.Count) - NotShippedGoods.QuantityOfGoodsInDocument AS Count,
	|	SUM(NotShippedGoods.NumberOfPackages) - NotShippedGoods.NumberOfPackagesInDocument AS NumberOfPackages,
	|	CASE
	|		WHEN NotShippedGoods.Products.UnitOfMeasure.MeasuredValueType IN (&TypesOfMeasuredQuantities)
	|			THEN CASE
	|					WHEN SUM(NotShippedGoods.NumberOfPackages) > NotShippedGoods.NumberOfPackagesInDocument + &AllowableVariance * NotShippedGoods.NumberOfPackagesInDocument / 100
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN SUM(NotShippedGoods.NumberOfPackages) - NotShippedGoods.NumberOfPackagesInDocument > 0
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS ItSOverkill
	|FROM
	|	ProductsFromProcessingForRequest AS NotShippedGoods
	|WHERE
	|	ISNULL(NotShippedGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	NotShippedGoods.Products,
	|	NotShippedGoods.Characteristic,
	|	NotShippedGoods.Package,
	|	NotShippedGoods.Purpose,
	|	NotShippedGoods.Series,
	|	NotShippedGoods.QuantityOfGoodsInDocument,
	|	NotShippedGoods.NumberOfPackagesInDocument,
	|	NotShippedGoods.Products.UnitOfMeasure.MeasuredValueType
	|
	|HAVING
	|	SUM(NotShippedGoods.NumberOfPackages) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	NotShippedGoods.Products,
	|	NotShippedGoods.Characteristic,
	|	NotShippedGoods.Package,
	|	NotShippedGoods.Purpose,
	|	NotShippedGoods.Series,
	|	(SUM(NotShippedGoods.NumberOfPackages) - NotShippedGoods.NumberOfPackagesInDocument) / NotShippedGoods.Package.NumberOfPackages,
	|	SUM(NotShippedGoods.NumberOfPackages) - NotShippedGoods.NumberOfPackagesInDocument,
	|	CASE
	|		WHEN SUM(NotShippedGoods.NumberOfPackages) - NotShippedGoods.NumberOfPackagesInDocument > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	ProductsFromProcessingForRequest AS NotShippedGoods
	|WHERE
	|	ISNULL(NotShippedGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	NotShippedGoods.Products,
	|	NotShippedGoods.Characteristic,
	|	NotShippedGoods.Package,
	|	NotShippedGoods.Purpose,
	|	NotShippedGoods.Series,
	|	NotShippedGoods.QuantityOfGoodsInDocument,
	|	NotShippedGoods.NumberOfPackagesInDocument,
	|	NotShippedGoods.Package.NumberOfPackages
	|
	|HAVING
	|	SUM(NotShippedGoods.NumberOfPackages) > 0";
	
	TypesOfMeasuredQuantities = Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits();
	QuantityTolerance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	Query.SetParameter("TypesOfMeasuredQuantities", TypesOfMeasuredQuantities);
	Query.SetParameter("AllowableVariance", QuantityTolerance);
	
	Result = Query.ExecuteBatch();
	
	UnassembledGoods = Result[1].Unload();
	NotShippedGoods = Result[3].Unload();
	
	ShortageConditions = New Structure("IsShortage", True);
	SurplusCondition = New Structure("ItSOverkill", True);
	
	SelectedGoodItems = UnassembledGoods.FindRows(ShortageConditions);
	ShippedGoods = NotShippedGoods.FindRows(SurplusCondition);
	
	Shortage.Clear();
	Unshipped.Clear();
	
	For Each LineProducts_ In SelectedGoodItems Do
		NewRow = Shortage.Add();
		FillPropertyValues(NewRow, LineProducts_);
	EndDo;
	
	For Each LineProducts_ In ShippedGoods Do
		NewRow = Unshipped.Add();
		FillPropertyValues(NewRow, LineProducts_);
	EndDo;
	
	If Not TransferResultToOrder Then
		
		Return Unshipped.Count() = 0
			And Shortage.Count() = 0;
		
	EndIf;
	
	TransferCompleted = True;
	
	If Unshipped.Count() = 0
		And Shortage.Count() = 0 Then
		
		TransferCompleted = TransferResultsToOrder(FieldsToConsider, ThisIsMRMCheck);
		
	EndIf;
	
	Return TransferCompleted;
	
EndFunction

Function ReflectDiscrepanciesInAccounting(FieldsToConsider, ThisIsMRMCheck = False) Export

	TransferCompleted = TransferResultsToOrder(FieldsToConsider, ThisIsMRMCheck);
	
	Return TransferCompleted;
	
EndFunction

Function TransferResultsToOrder(FieldsToConsider, ThisIsMRMCheck = False)
	
	ThisIsMovingOrder = TypeOf(WarehouseDocument) = Type("DocumentRef.GoodsTransferNote");
	
	DocumentObject = WarehouseDocument.GetObject();
	
	If CorrectionMode Then
		
		If ThisIsMovingOrder Then
			DocumentObject.ShippedGoods.Clear();
		Else
			
			ConditionForSelectingRows = New Structure;
			ConditionForSelectingRows.Insert("ThisIsAPackingList", False);
			ConditionForSelectingRows.Insert("PackingListParent", Documents.PackingList.EmptyRef());
			
			FoundRows = DocumentObject.ShippedGoods.FindRows(ConditionForSelectingRows);
			For Each ArrRow In FoundRows Do
				DocumentObject.ShippedGoods.Delete(ArrRow);
			EndDo;
			
		EndIf;
		
	Else
		ConditionForSelectingRows = New Structure;
		ConditionForSelectingRows.Insert("Action", Enums.ActionsWithGoodsIssueNoteRows.Pick);
		
		FoundRows = DocumentObject.ShippedGoods.FindRows(ConditionForSelectingRows);
		For Each ArrRow In FoundRows Do
			DocumentObject.ShippedGoods.Delete(ArrRow);
		EndDo;
	EndIf;
	
	For Each RowOfTables In Goods Do
		
		If RowOfTables.NumberOfPackages = 0 Then
			Continue;
		EndIf;
		
		LineProducts_ = DocumentObject.ShippedGoods.Add();
		FillPropertyValues(LineProducts_, RowOfTables);
		If Not ThisIsMovingOrder Then
			LineProducts_.PackingListParent = RowOfTables.PackingList;
			LineProducts_.PackingList = Documents.PackingList.EmptyRef();
		EndIf;
		LineProducts_.BatchesIndicationStatus = 0;
		If RowOfTables.DoNotShip Then
			LineProducts_.Action = Enums.ActionsWithGoodsIssueNoteRows.DoNotShip;
		Else	
			LineProducts_.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
		EndIf;
		
	EndDo;
	
	ThereAreLinesToSelect = False;
	
	If ShortageAccountingOption = "Get_" Then
		For Each RowOfTables In Shortage Do
			LineProducts_ = DocumentObject.ShippedGoods.Add();
			FillPropertyValues(LineProducts_, RowOfTables);
			LineProducts_.BatchesIndicationStatus = 0;
			LineProducts_.Count          = RowOfTables.QuantityShortage;
			LineProducts_.NumberOfPackages  = RowOfTables.NumberOfPackagesShortage;
			LineProducts_.Package		  	 = RowOfTables.Package;
			LineProducts_.Action = Enums.ActionsWithGoodsIssueNoteRows.Pick;
			ThereAreLinesToSelect = True;
		EndDo;
	EndIf;
	
	If ThisIsMovingOrder Then
		If Not ThereAreLinesToSelect Then
			DocumentObject.Status = Enums.TransferNoteStatuses.ToShip;
		Else
			DocumentObject.Status = Enums.TransferNoteStatuses.ForPicking;
		EndIf;
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject,Documents.GoodsTransferNote);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
		
		ProductsServer.FillInActionOnCompletenessOfProductPlaces(DocumentObject);
		
		ConditionForSelectingRows = New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip);		
		FoundRows = DocumentObject.ShippedGoods.FindRows(ConditionForSelectingRows);
		If FoundRows.Count() = DocumentObject.ShippedGoods.Count() Then
			DocumentObject.Status = Enums.TransferNoteStatuses.Accepted;
		EndIf;
		
	Else
		If Not ThereAreLinesToSelect Then
			DocumentObject.Status = ?(ValueIsFilled(NoteStatus), NoteStatus,
				Enums.GoodsIssueNoteStatuses.ToShip);
		Else
			DocumentObject.Status = Enums.GoodsIssueNoteStatuses.ForPicking;
		EndIf;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject,Documents.GoodsIssueNote);
		ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.ShippedGoods);
		
		ProductsServer.FillInActionOnCompletenessOfProductPlaces(DocumentObject);
		
		Documents.GoodsIssueNote.ChangeGoodsAccordingToOrdersForShippedGoods(DocumentObject, False, True);
		
		ConditionForSelectingRows = New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip);		
		FoundRows = DocumentObject.ShippedGoods.FindRows(ConditionForSelectingRows);
		If FoundRows.Count() = DocumentObject.ShippedGoods.Count() Then
			DocumentObject.Status = Enums.GoodsIssueNoteStatuses.Shipped_;
			DocumentObject.ShipmentUnderTransportationJob = False;
			DocumentObject.TransportationJob = Documents.TransportationJob.EmptyRef();
		EndIf;
				
		DocumentObject.TotalNumberOfPackageItems = PackingListsServer.NumberOfSeatsWH(DocumentObject.ShippedGoods);
	EndIf;
	
	DocumentDiscrepanciesObject = GenerateDocumentOfDiscrepancies(DocumentObject);
	
	TransferCompleted = True;
	
	If Not ThisIsMovingOrder Then
		AddPackingListLinesToOrder(DocumentObject);
		For Each Itm In PackageBarcodes Do
			NewString = DocumentObject.PackageBarcodes.Add();
			NewString.PackageBarcode = Itm.PackageBarcode;
		EndDo; 
	EndIf;
	
	TransferCompleted = True;
	If Not ThisIsMovingOrder
		And DocumentObject.ShippedGoods.Count() Then
		TransferCompleted = DocumentObject.CheckFilling();
		If Not TransferCompleted Then
			Return TransferCompleted;
		EndIf;
	EndIf;
	
	BeginTransaction();
	Try
		If DocumentDiscrepanciesObject <> Undefined Then
			DocumentDiscrepanciesObject.Write(DocumentWriteMode.Posting);
			ResultsReflectionDocument = DocumentDiscrepanciesObject.Ref;
		EndIf;	
		
		If Not ThisIsMovingOrder
			And DocumentObject.ShipmentUnderTransportationJob
			And Not ValueIsFilled(DocumentObject.TransportationJob) Then
			
			If Not ValueIsFilled(ThisObject.TransportationJob)
				And DocumentObject.Status = Enums.GoodsIssueNoteStatuses.ToShip Then
				
				If ThisIsMRMCheck Then
					DocumentObject.Status = Enums.GoodsIssueNoteStatuses.Verified;
				Else
					RollbackTransaction();
					
					TransferCompleted = False;
					MessageText = NStr("vi = 'Không có nhiệm vụ vận chuyển được lựa chọn. Không thể hoàn tất xác minh.';
										|ru = 'Не выбрано задание на перевозку. Невозможно завершить проверку.';
										|en = 'Itinerary is not selected. Cannot finish check.'; fa = 'Itinerary is not selected. Cannot finish check.';
										|it = 'Nessun task di spedizione selezionato. Impossibile completare il controllo.';
										|pl = 'Nie wybrano zadanie na transport. Nie można zakończyć weryfikację.';
										|tr = 'Taşıma planı seçilmedi. Doğrulama tamamlanamıyor.'");
					
					ResultsReflectionDocument = Documents.InventoryAdjustmentGoodsShipmentOrder.EmptyRef();
					
					CommonClientServer.MessageToUser(MessageText);
					
					Return TransferCompleted;
				EndIf;
				
			EndIf;
			
			DocumentObject.TransportationJob = ThisObject.TransportationJob;
			
		ElsIf Not ThisIsMovingOrder
			And Not ValueIsFilled(DocumentObject.TransportationJob)
			And ValueIsFilled(ThisObject.TransportationJob) Then
			
			DocumentObject.TransportationJob = ThisObject.TransportationJob;
			DocumentObject.ShipmentUnderTransportationJob = True;
			
		EndIf;
		
		If Not ThisIsMovingOrder
			And ValueIsFilled(DocumentObject.TransportationJob) Then
			
			DocumentObject.DeliveryProcedure = GoodsDelivery.DeliveryOrderInTransportOrder(DocumentObject.TransportationJob,
																								DocumentObject.Recipient);
			
		EndIf;
		
		If DocumentObject.ShippedGoods.Count() = 0 Then
			DocumentObject.Write(DocumentWriteMode.UndoPosting);
		Else
			DocumentObject.Write(DocumentWriteMode.Posting);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		CommonClientServer.MessageToUser(ErrorInfo().Description);
		ResultsReflectionDocument = Documents.InventoryAdjustmentGoodsShipmentOrder.EmptyRef();
		TransferCompleted = False;
	EndTry;
	
	If TransferCompleted
		And Not ThisIsMovingOrder Then
		PackingListsServer.SynchronizePackingListsWithSpendingOrder(DocumentObject.Ref, FieldsToConsider.PackingList_);
	EndIf;
	
	Return TransferCompleted;
	
EndFunction

Function GenerateDocumentOfDiscrepancies(OrderObject_)
	
	// 1. Let's calculate by the selection tasks how many were selected
	// 2. Let's calculate what the processing shows
	// 3. Let's calculate how many discrepancies have already been taken into account in the documents
	// 4. Let's calculate how many rows are shipped and unloaded in the order
	// 5. For the difference, we will create a new document of discrepancies.
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise, OrderObject_.Date) Then
		Return Undefined;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsFromProcessing.Products,
	|	GoodsFromProcessing.Characteristic,
	|	GoodsFromProcessing.Purpose,
	|	GoodsFromProcessing.Package,
	|	CASE
	|		WHEN NOT GoodsFromProcessing.BatchesIndicationStatus IN (0, 1, 2)
	|			THEN GoodsFromProcessing.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsFromProcessing.Count AS Count,
	|	GoodsFromProcessing.NumberOfPackages AS NumberOfPackages
	|INTO GoodsFromProcessing
	|FROM
	|	&GoodsFromProcessing AS GoodsFromProcessing
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package,
	|	NestedQuery.Series,
	|	SUM(CASE
	|			WHEN ISNULL(NestedQuery.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|				THEN NestedQuery.NumberOfPackages / NestedQuery.Package.NumberOfPackages
	|			ELSE NestedQuery.Count
	|		END) AS Count,
	|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages
	|INTO Discrepancies
	|FROM
	|	(SELECT
	|		GoodsFilter.Products AS Products,
	|		GoodsFilter.Characteristic AS Characteristic,
	|		GoodsFilter.Purpose AS Purpose,
	|		GoodsFilter.Package AS Package,
	|		GoodsFilter.Series AS Series,
	|		GoodsFilter.CountPicked AS Count,
	|		GoodsFilter.NumberOfPackagesPicked AS NumberOfPackages
	|	FROM
	|		Document.GoodsPickingPlacement.GoodsFilter AS GoodsFilter
	|	WHERE
	|		GoodsFilter.Ref.Posted
	|		AND GoodsFilter.Ref.OperationKind = VALUE(Enum.OperationKindsOfGoodsPlacementPicking.Filter)
	|		AND GoodsFilter.Ref.ReferenceOrder = &WarehouseDocument
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsFromProcessing.Products,
	|		GoodsFromProcessing.Characteristic,
	|		GoodsFromProcessing.Purpose,
	|		GoodsFromProcessing.Package,
	|		GoodsFromProcessing.Series,
	|		-GoodsFromProcessing.Count,
	|		-GoodsFromProcessing.NumberOfPackages
	|	FROM
	|		GoodsFromProcessing AS GoodsFromProcessing
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		Goods.Purpose,
	|		Goods.Package,
	|		Goods.Series,
	|		CASE
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|				THEN CASE
	|						WHEN Goods.Ref.WarehouseDocument = &WarehouseDocument
	|							THEN -Goods.Count
	|						ELSE Goods.Count
	|					END
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -Goods.Count
	|			ELSE Goods.Count
	|		END,
	|		CASE
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.MoveToOtherNote)
	|				THEN CASE
	|						WHEN Goods.Ref.WarehouseDocument = &WarehouseDocument
	|							THEN -Goods.NumberOfPackages
	|						ELSE Goods.NumberOfPackages
	|					END
	|			WHEN Goods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|				THEN -Goods.NumberOfPackages
	|			ELSE Goods.NumberOfPackages
	|		END
	|	FROM
	|		Document.InventoryAdjustmentGoodsShipmentOrder.Goods AS Goods
	|	WHERE
	|		Goods.Ref.Posted
	|		AND (Goods.Ref.WarehouseDocument = &WarehouseDocument
	|				OR Goods.Ref.RecipientNote = &WarehouseDocument)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShippedGoods.Products,
	|		ShippedGoods.Characteristic,
	|		ShippedGoods.Purpose,
	|		ShippedGoods.Package,
	|		CASE
	|			WHEN NOT ShippedGoods.BatchesIndicationStatus IN (0, 1, 2)
	|				THEN ShippedGoods.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END,
	|		-ShippedGoods.Count,
	|		-ShippedGoods.NumberOfPackages
	|	FROM
	|		Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|	WHERE
	|		ShippedGoods.Ref = &WarehouseDocument
	|		AND NOT ShippedGoods.ThisIsAPackingList
	|		AND ShippedGoods.Action IN (VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship), VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip))
	|		AND NOT &CorrectionMode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShippedGoods.Products,
	|		ShippedGoods.Characteristic,
	|		ShippedGoods.Purpose,
	|		ShippedGoods.Package,
	|		CASE
	|			WHEN NOT ShippedGoods.BatchesIndicationStatus IN (0, 1, 2)
	|				THEN ShippedGoods.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END,
	|		-ShippedGoods.Count,
	|		-ShippedGoods.NumberOfPackages
	|	FROM
	|		Document.GoodsTransferNote.ShippedGoods AS ShippedGoods
	|	WHERE
	|		ShippedGoods.Ref = &WarehouseDocument
	|		AND ShippedGoods.Action IN (VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship), VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip))
	|		AND NOT &CorrectionMode) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Discrepancies.Products,
	|	Discrepancies.Characteristic,
	|	Discrepancies.Purpose,
	|	Discrepancies.Package,
	|	Discrepancies.Series,
	|	CASE
	|		WHEN Discrepancies.NumberOfPackages < 0
	|			THEN VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|		ELSE VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|	END AS OperationKind,
	|	CASE
	|		WHEN Discrepancies.Count < 0
	|			THEN -Discrepancies.Count
	|		ELSE Discrepancies.Count
	|	END AS Count,
	|	CASE
	|		WHEN Discrepancies.NumberOfPackages < 0
	|			THEN -Discrepancies.NumberOfPackages
	|		ELSE Discrepancies.NumberOfPackages
	|	END AS NumberOfPackages
	|FROM
	|	Discrepancies AS Discrepancies
	|WHERE
	|	Discrepancies.NumberOfPackages <> 0";
	
	Query.SetParameter("GoodsFromProcessing", Goods.Unload());
	Query.SetParameter("WarehouseDocument", OrderObject_.Ref);
	Query.SetParameter("CorrectionMode", ThisObject.CorrectionMode);
	
	TableOfDiscrepancies = Query.Execute().Unload();
	
	If TableOfDiscrepancies.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DocumentDiscrepanciesObject = Documents.InventoryAdjustmentGoodsShipmentOrder.CreateDocument();
	
	DocumentDiscrepanciesObject.Date = CurrentSessionDate();
	DocumentDiscrepanciesObject.EmployeeResponsible = Users.CurrentUser();
	DocumentDiscrepanciesObject.WarehouseDocument = OrderObject_.Ref;        
	DocumentDiscrepanciesObject.Warehouse = Warehouse;
	DocumentDiscrepanciesObject.Premise = Premise;
	DocumentDiscrepanciesObject.ShippingZone = OrderObject_.ShippingZone;
	
	DocumentDiscrepanciesObject.Goods.Load(TableOfDiscrepancies);
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentDiscrepanciesObject, Documents.InventoryAdjustmentGoodsShipmentOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentDiscrepanciesObject, SeriesSpecificationParameters); 
	
	Return DocumentDiscrepanciesObject;
	
EndFunction

Procedure AddPackingListLinesToOrder(DocumentObject);
	
	If Not GetFunctionalOption("UsePackingLists") Then
		Return;
	EndIf;
	
	GoodsTable = DocumentObject.ShippedGoods.Unload(,"PackingListParent");
	GoodsTable.GroupBy("PackingListParent");
	
	For Each RowOfTables In GoodsTable Do
		
		If ValueIsFilled(RowOfTables.PackingListParent) Then
			
			SearchParameters = New Structure;
			SearchParameters.Insert("PackingList", RowOfTables.PackingListParent);
			SearchParameters.Insert("ThisIsAPackingList", True);
			
			FoundRows = DocumentObject.ShippedGoods.FindRows(SearchParameters);
			
			If FoundRows.Count() = 0 Then
				NewRow = DocumentObject.ShippedGoods.Add();
				NewRow.PackingList  = RowOfTables.PackingListParent;
				NewRow.ThisIsAPackingList = True;
				NewRow.Action = Enums.ActionsWithGoodsIssueNoteRows.Ship;
				NewRow.Count = 1;
				NewRow.NumberOfPackages = 1;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fill in the problem statuses.
// 
// Parameters:
//  FieldsToConsider - See WarehousesClientServer.FieldsTakenIntoAccountWhenCheckingSpendingOrder
//  CurrentData - LineOfATabularSection
//  ThisIsRemoval - Boolean - This is a deletion
//  FillingTS_ - Boolean - Fill in PM
// 
// Returns:
//  QueryResultSelection, Undefined - Fill the statuses of the problems
Function FillInProblemStatuses(FieldsToConsider, CurrentData, ThisIsRemoval, FillingTS_) Export
	
	Query = New Query;
	Query.Text =
	QueryTextTemporaryDocumentAndProcessingTables() + Chars.LF +
	"SELECT
	|	ProductsFromProcessingWithoutGrouping.LineNumber,
	|	GoodsFromProcessing.NumberOfPackages AS NumberOfPackagesAmount,
	|	GoodsFromProcessing.QuantityAmount AS QuantityAmount,
	|	GoodsFromProcessing.NumberOfPackagesDoNotShip,
	|	ISNULL(ProductsFromOrder.Count, 0) AS QuantityOfGoodsInDocument,
	|	ISNULL(ProductsFromOrder.NumberOfPackages, 0) AS NumberOfPackagesInDocument,
	|	CASE
	|		WHEN Goods.UnitOfMeasure.MeasuredValueType IN (&TypesOfMeasuredQuantities)
	|			THEN CASE
	|					WHEN GoodsFromProcessing.NumberOfPackages < ISNULL(ProductsFromOrder.NumberOfPackages, 0) - &AllowableVariance * ISNULL(ProductsFromOrder.NumberOfPackages, 0) / 100
	|							AND ISNULL(ProductsFromOrder.NumberOfPackages, 0) > 0
	|							AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|						THEN 0
	|					WHEN GoodsFromProcessing.NumberOfPackages <= ISNULL(ProductsFromOrder.NumberOfPackages, 0) + &AllowableVariance * ISNULL(ProductsFromOrder.NumberOfPackages, 0) / 100
	|							AND GoodsFromProcessing.NumberOfPackages >= ISNULL(ProductsFromOrder.NumberOfPackages, 0) - &AllowableVariance * ISNULL(ProductsFromOrder.NumberOfPackages, 0) / 100
	|							AND ProductsFromOrder.NumberOfPackages > 0
	|							AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|						THEN 1
	|					WHEN GoodsFromProcessing.NumberOfPackages <= ISNULL(ProductsFromOrder.NumberOfPackages, 0) + &AllowableVariance * ISNULL(ProductsFromOrder.NumberOfPackages, 0) / 100
	|							AND GoodsFromProcessing.NumberOfPackages >= ISNULL(ProductsFromOrder.NumberOfPackages, 0) - &AllowableVariance * ISNULL(ProductsFromOrder.NumberOfPackages, 0) / 100
	|							AND GoodsFromProcessing.DoNotShip = 1
	|							AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|						THEN 2
	|					WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 1
	|						THEN 3
	|					WHEN GoodsFromProcessing.NumberOfPackages > ISNULL(ProductsFromOrder.NumberOfPackages, 0)
	|							OR ISNULL(ProductsFromOrder.NumberOfPackages, 0) = 0
	|						THEN 4
	|					ELSE 404
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(ProductsFromProcessingWithoutGrouping.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|					THEN CASE
	|							WHEN GoodsFromProcessing.QuantityAmount < ISNULL(ProductsFromOrder.Count, 0)
	|									AND ISNULL(ProductsFromOrder.Count, 0) > 0
	|									AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|								THEN 0
	|							WHEN GoodsFromProcessing.QuantityAmount = ISNULL(ProductsFromOrder.Count, 0)
	|									AND ProductsFromOrder.Count > 0
	|									AND GoodsFromProcessing.DoNotShip = 0
	|								THEN 1
	|							WHEN GoodsFromProcessing.QuantityAmount = ISNULL(ProductsFromOrder.Count, 0)
	|									AND GoodsFromProcessing.DoNotShip = 1
	|									AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|								THEN 2
	|							WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 1
	|								THEN 3
	|							WHEN GoodsFromProcessing.QuantityAmount > ISNULL(ProductsFromOrder.Count, 0)
	|									OR ISNULL(ProductsFromOrder.Count, 0) = 0
	|								THEN 4
	|							ELSE 404
	|						END
	|				ELSE CASE
	|						WHEN GoodsFromProcessing.NumberOfPackages < ISNULL(ProductsFromOrder.NumberOfPackages, 0)
	|								AND ISNULL(ProductsFromOrder.NumberOfPackages, 0) > 0
	|								AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|							THEN 0
	|						WHEN GoodsFromProcessing.NumberOfPackages = ISNULL(ProductsFromOrder.NumberOfPackages, 0)
	|								AND ProductsFromOrder.NumberOfPackages > 0
	|								AND GoodsFromProcessing.DoNotShip = 0
	|							THEN 1
	|						WHEN GoodsFromProcessing.NumberOfPackages = ISNULL(ProductsFromOrder.NumberOfPackages, 0)
	|								AND GoodsFromProcessing.DoNotShip = 1
	|								AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|							THEN 2
	|						WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 1
	|							THEN 3
	|						WHEN GoodsFromProcessing.NumberOfPackages > ISNULL(ProductsFromOrder.NumberOfPackages, 0)
	|								OR ISNULL(ProductsFromOrder.NumberOfPackages, 0) = 0
	|							THEN 4
	|						ELSE 404
	|					END
	|			END
	|	END AS IssueStatus
	|INTO ProblemTable
	|FROM
	|	ProductsFromProcessingWithoutGrouping AS ProductsFromProcessingWithoutGrouping
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON ProductsFromProcessingWithoutGrouping.Products = Goods.Ref
	|		INNER JOIN GoodsFromProcessing AS GoodsFromProcessing
	|		ON ProductsFromProcessingWithoutGrouping.Products = GoodsFromProcessing.Products
	|			AND ProductsFromProcessingWithoutGrouping.Characteristic = GoodsFromProcessing.Characteristic
	|			AND ProductsFromProcessingWithoutGrouping.Purpose = GoodsFromProcessing.Purpose
	|			AND ProductsFromProcessingWithoutGrouping.Package = GoodsFromProcessing.Package
	|			AND ProductsFromProcessingWithoutGrouping.Series = GoodsFromProcessing.Series
	|		LEFT JOIN ProductsFromOrder AS ProductsFromOrder
	|		ON ProductsFromProcessingWithoutGrouping.Products = ProductsFromOrder.Products
	|			AND ProductsFromProcessingWithoutGrouping.Characteristic = ProductsFromOrder.Characteristic
	|			AND ProductsFromProcessingWithoutGrouping.Purpose = ProductsFromOrder.Purpose
	|			AND ProductsFromProcessingWithoutGrouping.Series = ProductsFromOrder.Series
	|			AND (ProductsFromProcessingWithoutGrouping.Package = ProductsFromOrder.Package)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProblemTable.LineNumber AS LineNumber,
	|	CASE
	|		WHEN ISNULL(ProductsFromProcessingWithoutGrouping.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItIsACargoItem,
	|	ProblemTable.NumberOfPackagesAmount AS NumberOfPackagesAmount,
	|	ProblemTable.QuantityAmount AS QuantityAmount,
	|	ProblemTable.QuantityOfGoodsInDocument AS QuantityOfGoodsInDocument,
	|	ProblemTable.NumberOfPackagesInDocument AS NumberOfPackagesInDocument,
	|	ProblemTable.NumberOfPackagesDoNotShip AS NumberOfPackagesDoNotShip,
	|	ProblemTable.IssueStatus
	|FROM
	|	ProductsFromProcessingWithoutGrouping AS ProductsFromProcessingWithoutGrouping
	|		INNER JOIN ProblemTable AS ProblemTable
	|		ON ProductsFromProcessingWithoutGrouping.LineNumber = ProblemTable.LineNumber
	|			AND (ProblemTable.IssueStatus <> ProductsFromProcessingWithoutGrouping.IssueStatus
	|				OR ProblemTable.QuantityAmount <> ProductsFromProcessingWithoutGrouping.QuantityAmount
	|				OR ProblemTable.NumberOfPackagesAmount <> ProductsFromProcessingWithoutGrouping.NumberOfPackagesAmount
	|				OR ProblemTable.NumberOfPackagesDoNotShip <> ProductsFromProcessingWithoutGrouping.NumberOfPackagesDoNotShip
	|				OR ProblemTable.NumberOfPackagesInDocument <> ProductsFromProcessingWithoutGrouping.NumberOfPackagesInDocument)
	|
	|ORDER BY
	|	LineNumber";
	
	TypesOfMeasuredQuantities = Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits();
	QuantityTolerance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();

	Query.SetParameter("Ref",WarehouseDocument);
	Query.SetParameter("GoodsFromProcessing",Goods.Unload());
	Query.SetParameter("PackingList_", FieldsToConsider.PackingList_);
	Query.SetParameter("ConsiderSeries", FieldsToConsider.ConsiderSeries);
	Query.SetParameter("SeriesStatusesThatAreNotTakenIntoAccount", FieldsToConsider.SeriesStatusesThatAreNotTakenIntoAccount);
	Query.SetParameter("TypesOfMeasuredQuantities", TypesOfMeasuredQuantities);
	Query.SetParameter("AllowableVariance", QuantityTolerance);

	If CurrentData = Undefined Then
		Query.SetParameter("AcrossTS",True);
		Query.SetParameter("ThisIsRemoval",False);
		Query.SetParameter("LineNumber",Undefined);
		Query.SetParameter("Products",Undefined);
		Query.SetParameter("Characteristic",Undefined);
		Query.SetParameter("Purpose", Undefined);
		Query.SetParameter("Package",Undefined);
		Query.SetParameter("Series",Undefined);
	Else
		Query.SetParameter("AcrossTS",False);
		Query.SetParameter("ThisIsRemoval",ThisIsRemoval);
		Query.SetParameter("LineNumber",CurrentData.LineNumber);
		Query.SetParameter("Products",CurrentData.Products);
		Query.SetParameter("Characteristic",CurrentData.Characteristic);
		Query.SetParameter("Purpose", CurrentData.Purpose);
		Query.SetParameter("Package",CurrentData.Package);
		Query.SetParameter("Series",CurrentData.Series);
	EndIf;
	
	Selection = Query.Execute().Select();
	
	If FillingTS_ Then
		While Selection.Next() Do
			FillPropertyValues(Goods[Selection.LineNumber - 1], Selection);
		EndDo;
		Return Undefined;
	Else
		Return Selection;
	EndIf;
		
EndFunction

Function SplitByNonLoadable(FieldsToConsider) Export
	
	Query = New Query;
	Query.Text =
	QueryTextTemporaryDocumentAndProcessingTables() +
	"
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromProcessing.Products,
	|	GoodsFromProcessing.Characteristic,
	|	GoodsFromProcessing.Purpose,
	|	GoodsFromProcessing.Package,
	|	GoodsFromProcessing.Count AS Count,
	|	ISNULL(ProductsFromOrder.NumberOfPackages, 0) AS NumberOfPackagesInDocument,
	|	GoodsFromProcessing.Series,
	|	GoodsFromProcessing.BatchesIndicationStatus
	|FROM
	|	GoodsFromProcessing AS GoodsFromProcessing
	|		LEFT JOIN ProductsFromOrder AS ProductsFromOrder
	|		ON GoodsFromProcessing.Products = ProductsFromOrder.Products
	|			AND GoodsFromProcessing.Characteristic = ProductsFromOrder.Characteristic
	|			AND GoodsFromProcessing.Purpose = ProductsFromOrder.Purpose
	|			AND GoodsFromProcessing.Package = ProductsFromOrder.Package
	|			AND GoodsFromProcessing.Series = ProductsFromOrder.Series
	|WHERE
	|	GoodsFromProcessing.NumberOfPackages > ISNULL(ProductsFromOrder.NumberOfPackages, 0)";	
	Query.SetParameter("Ref",WarehouseDocument);
	Query.SetParameter("GoodsFromProcessing",Goods.Unload());
	Query.SetParameter("PackingList_", FieldsToConsider.PackingList_);
	Query.SetParameter("ConsiderSeries", FieldsToConsider.ConsiderSeries);
	Query.SetParameter("SeriesStatusesThatAreNotTakenIntoAccount", FieldsToConsider.SeriesStatusesThatAreNotTakenIntoAccount);
	
	Query.SetParameter("AcrossTS",True);
	Query.SetParameter("ThisIsRemoval",False);
	Query.SetParameter("LineNumber",Undefined);
	Query.SetParameter("Products",Undefined);
	Query.SetParameter("Characteristic",Undefined);
	Query.SetParameter("Purpose",Undefined);
	Query.SetParameter("Package",Undefined);
	Query.SetParameter("Series",Undefined);

	Return Query.Execute().Select();
	
EndFunction

Function QueryTextTemporaryDocumentAndProcessingTables()
	                             
	ThisIsMovingOrder = TypeOf(WarehouseDocument) = Type("DocumentRef.GoodsTransferNote");
	If ThisIsMovingOrder Then
		QueryText =
		"SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus IN (&SeriesStatusesThatAreNotTakenIntoAccount)
		|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
		|		ELSE GoodsTable.Series
		|	END AS Series,
		|	CASE
		|		WHEN &PackingList_
		|				OR ISNULL(GoodsTable.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|			THEN GoodsTable.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 0
		|		ELSE GoodsTable.Count
		|	END AS Count,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 0
		|		WHEN &PackingList_
		|				OR ISNULL(GoodsTable.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|			THEN GoodsTable.NumberOfPackages
		|		ELSE GoodsTable.Count
		|	END AS NumberOfPackages
		|INTO ProductsFromRequestOrder
		|FROM
		|	Document.GoodsTransferNote.ShippedGoods AS GoodsTable
		|WHERE
		|	TRUE
		|	AND GoodsTable.Ref = &Ref
		|	AND &ConditionForSelectingRows
		|	AND (&AcrossTS
		|			OR GoodsTable.Products = &Products
		|				AND GoodsTable.Characteristic = &Characteristic
		|				AND GoodsTable.Purpose = &Purpose
		|				AND (GoodsTable.Package = &Package
		|					OR NOT &PackingList_)
		|				AND (GoodsTable.Series = &Series
		|					OR NOT &ConsiderSeries))";
	Else
		QueryText =
		"SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus IN (&SeriesStatusesThatAreNotTakenIntoAccount)
		|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
		|		ELSE GoodsTable.Series
		|	END AS Series,
		|	CASE
		|		WHEN &PackingList_
		|				OR ISNULL(GoodsTable.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|			THEN GoodsTable.Package
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 0
		|		ELSE GoodsTable.Count
		|	END AS Count,
		|	CASE
		|		WHEN GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)
		|			THEN 0
		|		WHEN &PackingList_
		|				OR ISNULL(GoodsTable.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|			THEN GoodsTable.NumberOfPackages
		|		ELSE GoodsTable.Count
		|	END AS NumberOfPackages
		|INTO ProductsFromRequestOrder
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
		|WHERE
		|	TRUE
		|	AND GoodsTable.Ref = &Ref
		|	AND &ConditionForSelectingRows
		|	AND (&AcrossTS
		|			OR GoodsTable.Products = &Products
		|				AND GoodsTable.Characteristic = &Characteristic
		|				AND GoodsTable.Purpose = &Purpose
		|				AND (GoodsTable.Package = &Package
		|					OR NOT &PackingList_)
		|				AND (GoodsTable.Series = &Series
		|					OR NOT &ConsiderSeries))";
	EndIf;
	QueryText = QueryText + "
	|;";
	
	QueryText = QueryText + Chars.LF +
	"SELECT
	|	CAST(GoodsTable.Products AS Catalog.Products) AS Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Package AS Package,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.NumberOfPackages) AS NumberOfPackages
	|INTO ProductsFromOrder
	|FROM
	|	ProductsFromRequestOrder AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromProcessing.Products,
	|	GoodsFromProcessing.Characteristic,
	|	GoodsFromProcessing.Purpose,
	|	CAST(GoodsFromProcessing.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	GoodsFromProcessing.Count AS Count,
	|	GoodsFromProcessing.NumberOfPackages AS NumberOfPackages,
	|	GoodsFromProcessing.NumberOfPackagesDoNotShip AS NumberOfPackagesDoNotShip,
	|	GoodsFromProcessing.NumberOfPackagesAmount AS NumberOfPackagesAmount,
	|	GoodsFromProcessing.QuantityAmount AS QuantityAmount,
	|	GoodsFromProcessing.NumberOfPackagesInDocument AS NumberOfPackagesInDocument,
	|	GoodsFromProcessing.Series AS Series,
	|	GoodsFromProcessing.BatchesIndicationStatus,
	|	GoodsFromProcessing.LineNumber,
	|	GoodsFromProcessing.IssueStatus,
	|	GoodsFromProcessing.DoNotShip
	|INTO ProductsFromProcessingForRequest
	|FROM
	|	&GoodsFromProcessing AS GoodsFromProcessing
	|WHERE
	|	(&AcrossTS
	|			OR GoodsFromProcessing.Products = &Products
	|				AND GoodsFromProcessing.Characteristic = &Characteristic
	|				AND GoodsFromProcessing.Purpose = &Purpose
	|				AND (GoodsFromProcessing.Package = &Package
	|					OR NOT &PackingList_)
	|				AND (GoodsFromProcessing.Series = &Series
	|					OR NOT &ConsiderSeries))
	|	AND (NOT &ThisIsRemoval
	|			OR GoodsFromProcessing.LineNumber <> &LineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsFromProcessing.Products,
	|	GoodsFromProcessing.Characteristic,
	|	GoodsFromProcessing.Purpose,
	|	CASE
	|		WHEN &PackingList_
	|				OR ISNULL(GoodsFromProcessing.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN CAST(GoodsFromProcessing.Package AS Catalog.PackagesAndUnitsOfMeasure)
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	GoodsFromProcessing.Count AS Count,
	|	CASE
	|		WHEN &PackingList_
	|				OR ISNULL(GoodsFromProcessing.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN GoodsFromProcessing.NumberOfPackages
	|		ELSE GoodsFromProcessing.Count
	|	END AS NumberOfPackages,
	|	GoodsFromProcessing.NumberOfPackagesDoNotShip AS NumberOfPackagesDoNotShip,
	|	GoodsFromProcessing.NumberOfPackagesAmount AS NumberOfPackagesAmount,
	|	GoodsFromProcessing.QuantityAmount AS QuantityAmount,
	|	GoodsFromProcessing.NumberOfPackagesInDocument AS NumberOfPackagesInDocument,
	|	CASE
	|		WHEN NOT GoodsFromProcessing.BatchesIndicationStatus IN (&SeriesStatusesThatAreNotTakenIntoAccount)
	|			THEN GoodsFromProcessing.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsFromProcessing.BatchesIndicationStatus,
	|	GoodsFromProcessing.LineNumber,
	|	GoodsFromProcessing.IssueStatus,
	|	GoodsFromProcessing.DoNotShip
	|INTO ProductsFromProcessingWithoutGrouping
	|FROM
	|	ProductsFromProcessingForRequest AS GoodsFromProcessing
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(ProductsFromProcessingWithoutGrouping.Products AS Catalog.Products) AS Products,
	|	ProductsFromProcessingWithoutGrouping.Characteristic,
	|	ProductsFromProcessingWithoutGrouping.Purpose,
	|	ProductsFromProcessingWithoutGrouping.Series,
	|	ProductsFromProcessingWithoutGrouping.Package,
	|	SUM(ProductsFromProcessingWithoutGrouping.NumberOfPackages) AS NumberOfPackages
	|INTO GoodsFromProcessingInCommodityPlacesShipped
	|FROM
	|	ProductsFromProcessingWithoutGrouping AS ProductsFromProcessingWithoutGrouping
	|WHERE
	|	ISNULL(ProductsFromProcessingWithoutGrouping.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|
	|GROUP BY
	|	CAST(ProductsFromProcessingWithoutGrouping.Products AS Catalog.Products),
	|	ProductsFromProcessingWithoutGrouping.Characteristic,
	|	ProductsFromProcessingWithoutGrouping.Purpose,
	|	ProductsFromProcessingWithoutGrouping.Package,
	|	ProductsFromProcessingWithoutGrouping.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsFromProcessingInCommodityPlaces.Products,
	|	GoodsFromProcessingInCommodityPlaces.Characteristic,
	|	GoodsFromProcessingInCommodityPlaces.Purpose,
	|	GoodsFromProcessingInCommodityPlaces.Series,
	|	PackagesAndUnitsOfMeasure.Ref AS CargoItem,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages
	|INTO ProductItemsLocations
	|FROM
	|	GoodsFromProcessingInCommodityPlacesShipped AS GoodsFromProcessingInCommodityPlaces
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON GoodsFromProcessingInCommodityPlaces.Products.PackagingGroup = PackagesAndUnitsOfMeasure.Owner
	|WHERE
	|	NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	GoodsFromProcessingInCommodityPlaces.Products,
	|	GoodsFromProcessingInCommodityPlaces.Characteristic,
	|	GoodsFromProcessingInCommodityPlaces.Purpose,
	|	GoodsFromProcessingInCommodityPlaces.Series,
	|	PackagesAndUnitsOfMeasure.Ref,
	|	PackagesAndUnitsOfMeasure.NumberOfPackages
	|FROM
	|	GoodsFromProcessingInCommodityPlacesShipped AS GoodsFromProcessingInCommodityPlaces
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON GoodsFromProcessingInCommodityPlaces.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|			AND GoodsFromProcessingInCommodityPlaces.Products = PackagesAndUnitsOfMeasure.Owner
	|WHERE
	|	NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductItemsLocations.Products,
	|	ProductItemsLocations.Characteristic,
	|	ProductItemsLocations.Purpose,
	|	ProductItemsLocations.Series,
	|	MIN(CASE
	|			WHEN ISNULL(GoodsFromProcessingInCommodityPlaces.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages - (CAST(ISNULL(GoodsFromProcessingInCommodityPlaces.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))) >= 0
	|				THEN CAST(ISNULL(GoodsFromProcessingInCommodityPlaces.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))
	|			ELSE (CAST(ISNULL(GoodsFromProcessingInCommodityPlaces.NumberOfPackages, 0) / ProductItemsLocations.NumberOfPackages AS NUMBER(12, 0))) - 1
	|		END) AS Count
	|INTO GoodsFromProcessingInCommodityPlacesSetsShipped
	|FROM
	|	ProductItemsLocations AS ProductItemsLocations
	|		LEFT JOIN GoodsFromProcessingInCommodityPlacesShipped AS GoodsFromProcessingInCommodityPlaces
	|		ON ProductItemsLocations.Products = GoodsFromProcessingInCommodityPlaces.Products
	|			AND ProductItemsLocations.Characteristic = GoodsFromProcessingInCommodityPlaces.Characteristic
	|			AND ProductItemsLocations.Purpose = GoodsFromProcessingInCommodityPlaces.Purpose
	|			AND ProductItemsLocations.Series = GoodsFromProcessingInCommodityPlaces.Series
	|			AND ProductItemsLocations.CargoItem = GoodsFromProcessingInCommodityPlaces.Package
	|
	|GROUP BY
	|	ProductItemsLocations.Products,
	|	ProductItemsLocations.Characteristic,
	|	ProductItemsLocations.Purpose,
	|	ProductItemsLocations.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsFromProcessingWithoutGrouping.Products,
	|	ProductsFromProcessingWithoutGrouping.Characteristic,
	|	ProductsFromProcessingWithoutGrouping.Purpose,
	|	ProductsFromProcessingWithoutGrouping.Package,
	|	CASE
	|		WHEN ProductsFromProcessingWithoutGrouping.Package = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN SUM(CASE
	|						WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|							THEN ProductsFromProcessingWithoutGrouping.NumberOfPackages
	|						ELSE 0
	|					END) / ProductsFromProcessingWithoutGrouping.Package.NumberOfPackages
	|		ELSE SUM(CASE
	|					WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|						THEN ProductsFromProcessingWithoutGrouping.Count
	|					ELSE 0
	|				END)
	|	END AS Count,
	|	SUM(CASE
	|			WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 0
	|				THEN ProductsFromProcessingWithoutGrouping.NumberOfPackages
	|			ELSE 0
	|		END) AS NumberOfPackages,
	|	CASE
	|		WHEN ProductsFromProcessingWithoutGrouping.Package = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN SUM(CASE
	|						WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 1
	|							THEN ProductsFromProcessingWithoutGrouping.NumberOfPackages
	|						ELSE 0
	|					END) / ProductsFromProcessingWithoutGrouping.Package.NumberOfPackages
	|		ELSE SUM(CASE
	|					WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 1
	|						THEN ProductsFromProcessingWithoutGrouping.Count
	|					ELSE 0
	|				END)
	|	END AS QuantityNotToShip,
	|	SUM(CASE
	|			WHEN ProductsFromProcessingWithoutGrouping.DoNotShip = 1
	|				THEN ProductsFromProcessingWithoutGrouping.NumberOfPackages
	|			ELSE 0
	|		END) AS NumberOfPackagesDoNotShip,
	|	ProductsFromProcessingWithoutGrouping.Series,
	|	ISNULL(GoodsFromProcessingInCommodityPlacesSetsShipped.Count, ProductsFromProcessingWithoutGrouping.QuantityAmount) AS QuantityAmount,
	|	MAX(ProductsFromProcessingWithoutGrouping.DoNotShip) AS DoNotShip,
	|	MAX(ProductsFromProcessingWithoutGrouping.BatchesIndicationStatus) AS BatchesIndicationStatus
	|INTO GoodsFromProcessing
	|FROM
	|	ProductsFromProcessingWithoutGrouping AS ProductsFromProcessingWithoutGrouping
	|		LEFT JOIN GoodsFromProcessingInCommodityPlacesSetsShipped AS GoodsFromProcessingInCommodityPlacesSetsShipped
	|		ON ProductsFromProcessingWithoutGrouping.Products = GoodsFromProcessingInCommodityPlacesSetsShipped.Products
	|			AND ProductsFromProcessingWithoutGrouping.Characteristic = GoodsFromProcessingInCommodityPlacesSetsShipped.Characteristic
	|			AND ProductsFromProcessingWithoutGrouping.Purpose = GoodsFromProcessingInCommodityPlacesSetsShipped.Purpose
	|			AND ProductsFromProcessingWithoutGrouping.Series = GoodsFromProcessingInCommodityPlacesSetsShipped.Series
	|			AND (ISNULL(ProductsFromProcessingWithoutGrouping.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|
	|GROUP BY
	|	ProductsFromProcessingWithoutGrouping.Products,
	|	ProductsFromProcessingWithoutGrouping.Characteristic,
	|	ProductsFromProcessingWithoutGrouping.Purpose,
	|	ProductsFromProcessingWithoutGrouping.Package,
	|	ProductsFromProcessingWithoutGrouping.Series,
	|	ISNULL(GoodsFromProcessingInCommodityPlacesSetsShipped.Count, ProductsFromProcessingWithoutGrouping.QuantityAmount),
	|	ProductsFromProcessingWithoutGrouping.Package.NumberOfPackages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsFromRequestOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsFromProcessingForRequest
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsFromProcessingInCommodityPlacesShipped
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductItemsLocations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsFromProcessingInCommodityPlacesSetsShipped";
	
	QueryText = QueryText + ";";
	
	QueryText = StrReplace(QueryText, "&ConditionForSelectingRows", DataProcessors.GoodsQuantityCheckInDocument.ConditionForSelectingRows(ThisObject)); 
	
	Return QueryText;
EndFunction

#EndRegion

#EndIf
