#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
	If Not (FillingData <> Undefined
		And Documents.AllRefsType().ContainsType(TypeOf(FillingData))) Then
		
		Return;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsPickingPlacement") Then
		
		AttributesValues = Common.ObjectAttributesValues(FillingData,"Posted,Status,Warehouse,Premise");
		
		If Not AttributesValues.Posted Then
			MessageText = NStr("vi = 'Chỉ có thể nhập trên cơ sở theo chứng từ đã kết chuyển!';
								|ru = 'Ввод на основании возможен только по проведенным документам!';
								|en = 'You can generate a new document only from a posted document.'; fa = 'You can generate a new document only from a posted document.';
								|it = 'L''inserimento nella ricevuta è possibile solamente attraverso i documenti già emessi!';
								|pl = 'Wstęp na podstawie jest możliwy tylko na podstawie zaksięgowanych dokumentów!';
								|tr = 'Esaslı giriş, yalnızca kaydedilen belgelere göre mümkündür!'");
			Raise MessageText;
		EndIf;
		
		If AttributesValues.Status <> Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors Then
			MessageText = NStr("vi = 'Có thể thiết lập phong tỏa chỉ trên cơ sở nhiệm vụ lọc (sắp xếp) ở trạng thái %Completed2%';
								|ru = 'Ввод установки блокировки возможен только на основании задания на отбор (размещение) в статусе %Completed2%';
								|en = 'You can lock a storage bin only if the document status is %Completed2%'; fa = 'You can lock a storage bin only if the document status is %Completed2%';
								|it = 'L''inserimento dell''installazione di blocco è possibile solo sulla base di un''attività di selezione (posizionamento) nello stato %Completed2%';
								|pl = 'Wprowadzenie ustawienia blokowania jest możliwe tylko na podstawie zadania wyboru (umieszczenia) ze statusem %Completed2%';
								|tr = 'Kilit ayarı, yalnızca durumdaki bir filtre (yerleştirme) görevi temelinde girilebilir %Completed2%'");
			MessageText = StrReplace(MessageText,"%Completed2%", Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors);
			Raise MessageText;
		Else
			
			FillPropertyValues(ThisObject,AttributesValues, "Warehouse, Premise");
			
			Query = New Query;
			Query.Text =
			"SELECT
			|	NestedQuery.Cell,
			|	SUM(NestedQuery.NumberOfCellsPlacement) AS NumberOfCellsPlacement,
			|	SUM(NestedQuery.NumberOfSelectionCells) AS NumberOfSelectionCells
			|FROM
			|	(SELECT
			|		SelectionProductPlacementProductsSelection.Cell AS Cell,
			|		0 AS NumberOfCellsPlacement,
			|		1 AS NumberOfSelectionCells
			|	FROM
			|		Document.GoodsPickingPlacement.GoodsFilter AS SelectionProductPlacementProductsSelection
			|	WHERE
			|		SelectionProductPlacementProductsSelection.Ref = &Ref
			|		AND SelectionProductPlacementProductsSelection.NumberOfPackages <> SelectionProductPlacementProductsSelection.NumberOfPackagesPicked
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		SelectionProductPlacementProductsPlacement.Cell,
			|		1,
			|		0
			|	FROM
			|		Document.GoodsPickingPlacement.GoodsPlacement AS SelectionProductPlacementProductsPlacement
			|	WHERE
			|		SelectionProductPlacementProductsPlacement.Ref = &Ref
			|		AND SelectionProductPlacementProductsPlacement.NumberOfPackages <> SelectionProductPlacementProductsPlacement.NumberOfPackagesPlaced) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Cell
			|
			|ORDER BY
			|	NestedQuery.Cell.Code";
			
			Query.SetParameter("Ref",FillingData);
			
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				
				NewRow = StorageBins.Add();
				NewRow.Cell = Selection.Cell;
				
				If Selection.NumberOfSelectionCells > 0
					And Selection.NumberOfCellsPlacement = 0 Then
					// So the quantities do not converge only in PM
					// , we block the selection for selection.
					NewRow.LockType = Enums.TypesOfWarehouseBinLocks.Filter;
				ElsIf Selection.NumberOfCellsPlacement > 0
					And Selection.NumberOfSelectionCells = 0 Then
					// So the quantities do not converge only in PM
					// , we block placement for placement.
					NewRow.LockType = Enums.TypesOfWarehouseBinLocks.Location;
				Else
					// So the quantities do not converge in both PM
					// , we block them completely.
					NewRow.LockType = Enums.TypesOfWarehouseBinLocks.Full;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
		
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	CheckCellsBeforeLocking(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);

EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);

EndProcedure

#EndRegion

#Region Other

Procedure CheckCellsBeforeLocking(Cancel)
	
	Block = New DataLock;

	LockItem = Block.Add("InformationRegister.StorageBinsLocks");
	LockItem.Mode          = DataLockMode.Exclusive;
	LockItem.DataSource = StorageBins;
	LockItem.UseFromDataSource("Cell", "Cell");
	
	LockItem = Block.Add("AccumulationRegister.GoodsInStorageBins");
	LockItem.Mode          = DataLockMode.Shared;
	LockItem.DataSource = StorageBins;
	LockItem.UseFromDataSource("Cell", "Cell");
	
	Block.Lock();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsInStorageBinsBalance.Cell AS Cell,
	|	GoodsInStorageBinsBalance.ForPickingBalance AS ForPickingBalance,
	|	GoodsInStorageBinsBalance.ForPlacementBalance AS ForPlacementBalance,
	|	SetStorageBinLocksStorageBins.LockType AS LockType
	|FROM
	|	Document.SetStorageBinLocks.StorageBins AS SetStorageBinLocksStorageBins
	|		INNER JOIN AccumulationRegister.GoodsInStorageBins.Balance(
	|				,
	|				Cell IN
	|					(SELECT
	|						SetStorageBinLocksStorageBins.Cell AS Cell
	|					FROM
	|						Document.SetStorageBinLocks.StorageBins AS SetStorageBinLocksStorageBins
	|					WHERE
	|						SetStorageBinLocksStorageBins.Ref = &Ref)) AS GoodsInStorageBinsBalance
	|		ON SetStorageBinLocksStorageBins.Cell = GoodsInStorageBinsBalance.Cell
	|WHERE
	|	(GoodsInStorageBinsBalance.ForPickingBalance <> 0
	|				AND (SetStorageBinLocksStorageBins.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Full)
	|					OR SetStorageBinLocksStorageBins.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Filter))
	|			OR GoodsInStorageBinsBalance.ForPlacementBalance <> 0
	|				AND (SetStorageBinLocksStorageBins.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Full)
	|					OR SetStorageBinLocksStorageBins.LockType = VALUE(Enum.TypesOfWarehouseBinLocks.Location)))
	|	AND SetStorageBinLocksStorageBins.Ref = &Ref
	|
	|ORDER BY
	|	Cell";
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Selection.LockType = Enums.TypesOfWarehouseBinLocks.Location Then
			MessageText = NStr("vi = 'Không thể phong tỏa ô hàng %Cell% với kiểu phong tỏa ""%LockType%"":
									   |có nhiệm vụ xếp hàng hóa vào ô hàng chưa được thực hiện';
									   |ru = 'Ячейка %Cell% не может быть заблокирована с типом блокировки ""%LockType%"":
									   |есть невыполненные задания на размещение товара в ячейку';
									   |en = 'Cannot lock storage bin %Cell% to perform operation: %LockType%.:
									   |The storage bin is busy with another operation: Inventory put-away.'; fa = 'Cannot lock storage bin %Cell% to perform operation: %LockType%.:
									   |The storage bin is busy with another operation: Inventory put-away.';
									   |it = 'La cella%Cell% non può essere bloccata con la modalità di blocco ""%LockType%"":
									   |ci sono compiti in sospeso nella sistemazione del prodotto nella cella.';
									   |pl = 'Komórki %Cell% nie można zablokować za pomocą typu blokowania ""%LockType%"":
									   | istnieją nie wykonane zadania dotyczące umieszczania towarów w komórce';
									   |tr = '%Cell% hücresi ""%LockType%"" kilit türü ile kilitlenemez:
									   |hücreye ürün yerleştirmek için yerine getirilmemiş görevler vardır'");
		ElsIf Selection.LockType = Enums.TypesOfWarehouseBinLocks.Filter Then
			MessageText = NStr("vi = 'Không thể phong tỏa ô hàng %Cell% với kiểu phong tỏa ""%LockType%"":
									   |có nhiệm vụ lấy hàng hóa ra khỏi ô hàng chưa được thực hiện';
									   |ru = 'Ячейка %Cell% не может быть заблокирована с типом блокировки ""%LockType%"":
									   |есть невыполненные задания на отбор товара из ячейки';
									   |en = 'Cannot lock storage bin %Cell% to perform operation: %LockType%.:
									   |The storage bin is busy with another operation: Inventory picking.'; fa = 'Cannot lock storage bin %Cell% to perform operation: %LockType%.:
									   |The storage bin is busy with another operation: Inventory picking.';
									   |it = 'La cella%Cell% non può essere bloccata con la modalità di blocco ""%LockType%"":
									   |ci sono compiti in sospeso nella selezione del prodotto nella cella';
									   |pl = 'Komórki %Cell% nie można zablokować za pomocą typu blokowania ""%LockType%"":
									   | istnieją nie wykonane zadania dotyczące selekci towarów z komórki';
									   |tr = '%Cell% hücresi ""%LockType%"" kilit türü ile kilitlenemez:
									   |hücreden ürün filtresi için yerine getirilmemiş görevler var'");
		ElsIf Selection.LockType = Enums.TypesOfWarehouseBinLocks.Full Then
			MessageText = NStr("vi = 'Không thể phong tỏa ô hàng %Cell% với kiểu phong tỏa ""%LockType%"":
									   |có nhiệm vụ %Action% chưa được thực hiện';
									   |ru = 'Ячейка %Cell% не может быть заблокирована с типом блокировки ""%LockType%"":
									   |есть невыполненные задания на %Action%';
									   |en = 'Cannot lock storage bin %Cell% to perform operation: %LockType%.
									   |The storage bin is busy with another operation: %Action%.'; fa = 'Cannot lock storage bin %Cell% to perform operation: %LockType%.
									   |The storage bin is busy with another operation: %Action%.';
									   |it = 'La cella %Cell% non può essere bloccata con la modalità di blocco ""%LockType%"": 
									   |ci sono compiti in sospeso in %Action%';
									   |pl = 'Komórki %Cell% nie można zablokować za pomocą typu blokowania ""%LockType%"":
									   | istnieją nie wykonane zadania na %Action%';
									   |tr = '%Cell% hücresi ""%LockType%"" kilit türü ile kilitlenemez:
									   |yerine getirilmemiş görevler var %Action%'");
			//
			If Selection.ForPickingBalance <> 0
			     And Selection.ForPlacementBalance <> 0 Then
				 ActionText = NStr("vi = 'lấy ra và sắp xếp hàng hóa vào ô';
									|ru = 'отбор и размещение товара в ячейку';
									|en = 'Inventory transfer'; fa = 'انتقال موجودی';
									|it = 'scelta e sistemazione del prodotto nella cella';
									|pl = 'selekcje i przemieszczania towaru w komórce';
									|tr = 'hücreye ürün filtresi ve yerleştirilmesi'");
			ElsIf Selection.ForPickingBalance <> 0 Then
				 ActionText = NStr("vi = 'lấy ra hàng hóa từ ô hàng';
									|ru = 'отбор товара из ячейки';
									|en = 'Inventory picking'; fa = 'Inventory picking';
									|it = 'scelta prodotto dalla cella';
									|pl = 'selekcje towaru w komórce';
									|tr = 'hücreden ürün filtresi'");
			ElsIf Selection.ForPlacementBalance <> 0 Then
				 ActionText = NStr("vi = 'sắp xếp vào ô hàng';
									|ru = 'размещение в ячейку';
									|en = 'Inventory put-away'; fa = 'جای‌گذاری موجودی';
									|it = 'sistemazione nella cella';
									|pl = 'przemieszczanie do komórki';
									|tr = 'hücreye yerleştirme'");
			EndIf;
			
			MessageText = StrReplace(MessageText, "%Action%", ActionText);
			
		EndIf;
			
		MessageText = StrReplace(MessageText, "%Cell%", Selection.Cell);
		MessageText = StrReplace(MessageText, "%LockType%", Selection.LockType);
		
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf