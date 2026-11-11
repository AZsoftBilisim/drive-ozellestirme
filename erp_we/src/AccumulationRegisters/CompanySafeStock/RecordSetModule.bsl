#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	AdditionalProperties.Insert("NotReflectedInBudgeting");
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
	EndIf;
	
	InventoriesServer.PreserveOriginalRegisteredRecordsOfGoodsAndReserves(Filter.Recorder.Value,
		AdditionalProperties.TempTablesManager);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	
	QueryText =
	"SELECT
	|	TableWhenWriting.Period AS Period,
	|	TableWhenWriting.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableWhenWriting.ItemsLocationAttributes.Products.ItemsType AS ItemsType,
	|	TableWhenWriting.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableWhenWriting.Organization AS Organization,
	|	TableWhenWriting.CorCompany,
	|	TableWhenWriting.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableWhenWriting.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableWhenWriting.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableWhenWriting.CorInventoryOwnerAttribute.InventoryType AS TypeOfStocksCorTypeOfStocks,
	|	TableWhenWriting.InventoryOwnerAttribute.Organization AS OrganizationOfInventoryType,
	|	TableWhenWriting.CCDNumber AS CCDNumber,
	|	TableWhenWriting.Count,
	|	TableWhenWriting.RecordType AS RecordType,
	|	TRUE AS ThisIsNewMovement
	|INTO DimensionCompanySafeStock
	|FROM
	|	AccumulationRegister.CompanySafeStock AS TableWhenWriting
	|WHERE
	|	TableWhenWriting.Recorder = &Recorder";
	
	If DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	TableBeforeWrite.Period,
		|	TableBeforeWrite.ItemsLocationAttributes,
		|	TableBeforeWrite.ItemsLocationAttributes.Products.ItemsType,
		|	TableBeforeWrite.ItemsLocationAttributes.StorageLocation,
		|	TableBeforeWrite.Organization,
		|	TableBeforeWrite.CorCompany,
		|	TableBeforeWrite.InventoryOwnerAttribute,
		|	TableBeforeWrite.CorInventoryOwnerAttribute,
		|	TableBeforeWrite.InventoryOwnerAttribute.InventoryType,
		|	TableBeforeWrite.CorInventoryOwnerAttribute.InventoryType,
		|	TableBeforeWrite.InventoryOwnerAttribute.Organization,
		|	TableBeforeWrite.CCDNumber,
		|	TableBeforeWrite.Count,
		|	TableBeforeWrite.RecordType,
		|	FALSE
		|FROM
		|	RegisteredRecordsReservesGoodsOfOrganizationsBeforeRecording AS TableBeforeWrite
		|";
	EndIf;
	
	QueryText = QueryText + 
	"
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText +
	"SELECT
	|	MAX(NestedQuery.Period) AS Period,
	|	NULL AS RecordType,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	""BalanceError"" AS ErrorType
	|FROM
	|	(SELECT
	|		CompanySafeStock.Period AS Period,
	|		CompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanySafeStock.Organization AS Organization,
	|		CompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber AS CCDNumber,
	|		CompanySafeStock.Count AS Count
	|	FROM
	|		DimensionCompanySafeStock AS CompanySafeStock
	|	WHERE
	|		CompanySafeStock.ThisIsNewMovement
	|		AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanySafeStock.Period,
	|		CompanySafeStock.ItemsLocationAttributes,
	|		CompanySafeStock.CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber,
	|		-CompanySafeStock.Count
	|	FROM
	|		DimensionCompanySafeStock AS CompanySafeStock
	|	WHERE
	|		CompanySafeStock.ThisIsNewMovement
	|		AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanySafeStock.Period,
	|		CompanySafeStock.ItemsLocationAttributes,
	|		CompanySafeStock.Organization,
	|		CompanySafeStock.InventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber,
	|		CompanySafeStock.Count
	|	FROM
	|		DimensionCompanySafeStock AS CompanySafeStock
	|	WHERE
	|		CompanySafeStock.ThisIsNewMovement
	|		AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanySafeStock.Period,
	|		CompanySafeStock.ItemsLocationAttributes,
	|		CompanySafeStock.CorCompany,
	|		CompanySafeStock.CorInventoryOwnerAttribute,
	|		CompanySafeStock.CCDNumber,
	|		-CompanySafeStock.Count
	|	FROM
	|		DimensionCompanySafeStock AS CompanySafeStock
	|	WHERE
	|		CompanySafeStock.ThisIsNewMovement
	|		AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.CCDNumber,
	|	NestedQuery.InventoryOwnerAttribute,
	|	NestedQuery.Organization,
	|	NestedQuery.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(NestedQuery.Count) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(CompanySafeStock.Period, MONTH),
	|	CompanySafeStock.RecordType,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber,
	|	""ErrorZeroQuantity""
	|FROM
	|	DimensionCompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.ThisIsNewMovement
	|
	|GROUP BY
	|	BEGINOFPERIOD(CompanySafeStock.Period, MONTH),
	|	CompanySafeStock.CCDNumber,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.CorCompany,
	|	CompanySafeStock.CorInventoryOwnerAttribute,
	|	CompanySafeStock.RecordType
	|
	|HAVING
	|	SUM(CASE
	|			WHEN CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CompanySafeStock.Count
	|			ELSE -CompanySafeStock.Count
	|		END) = 0
	|
	|UNION ALL
	|
	|SELECT
	|	CompanySafeStock.Period,
	|	NULL,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber,
	|	""InventoryTypeOwnershipError""
	|FROM
	|	DimensionCompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.ThisIsNewMovement
	|	AND CompanySafeStock.Organization <> CompanySafeStock.OrganizationOfInventoryType
	|
	|UNION ALL
	|
	|SELECT
	|	CompanySafeStock.Period,
	|	NULL,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber,
	|	""ErrorInSelectedInventoryType""
	|FROM
	|	DimensionCompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.ThisIsNewMovement
	|	AND CompanySafeStock.Organization = CompanySafeStock.CorCompany
	|	AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT CompanySafeStock.TypeOfStocksCorTypeOfStocks IN (
	|									VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|									VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|									VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|									VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|
	|UNION ALL
	|
	|SELECT
	|	CompanySafeStock.Period,
	|	NULL,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber,
	|	""ErrorArrivalOfReserveForGoodsInStorageWithRightToSell""
	|FROM
	|	DimensionCompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CompanySafeStock.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|
	|UNION ALL
	|
	|SELECT
	|	CompanySafeStock.Period,
	|	NULL,
	|	CompanySafeStock.ItemsLocationAttributes,
	|	CompanySafeStock.Organization,
	|	CompanySafeStock.InventoryOwnerAttribute,
	|	CompanySafeStock.CCDNumber,
	|	""ProductTypeError""
	|FROM
	|	DimensionCompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.ThisIsNewMovement
	|	AND CompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT CompanySafeStock.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ENDOFPERIOD(DimensionCompanySafeStock.Period, MONTH) AS Period,
	|	DimensionCompanySafeStock.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DimensionCompanySafeStock.Organization AS Organization,
	|	DimensionCompanySafeStock.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DimensionCompanySafeStock.CCDNumber AS CCDNumber
	|INTO RegisteredRecordsReservesOfGoodsOfOrganizationsChange
	|FROM
	|	DimensionCompanySafeStock AS DimensionCompanySafeStock
	|WHERE
	|	NOT DimensionCompanySafeStock.Warehouse REFS Catalog.BusinessStructure
	|	AND NOT &DoNotCheckExcessStorno
	|
	|GROUP BY
	|	ENDOFPERIOD(DimensionCompanySafeStock.Period, MONTH),
	|	DimensionCompanySafeStock.ItemsLocationAttributes,
	|	DimensionCompanySafeStock.Organization,
	|	DimensionCompanySafeStock.InventoryOwnerAttribute,
	|	DimensionCompanySafeStock.CCDNumber
	|
	|HAVING
	// We check only the reduction of the remainder
	|	SUM(CASE
	|			WHEN DimensionCompanySafeStock.RecordType = VALUE(AccumulationRecordType.Expense)
	|						AND DimensionCompanySafeStock.ThisIsNewMovement
	|					OR DimensionCompanySafeStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						AND NOT DimensionCompanySafeStock.ThisIsNewMovement
	|				THEN -DimensionCompanySafeStock.Count
	|			ELSE DimensionCompanySafeStock.Count
	|		END) < 0
	|
	|INDEX BY
	|	DimensionCompanySafeStock.ItemsLocationAttributes,
	|	DimensionCompanySafeStock.Organization,
	|	DimensionCompanySafeStock.InventoryOwnerAttribute,
	|	DimensionCompanySafeStock.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(RegisteredRecordsReservesOfGoodsOfOrganizationsChange.Period) AS Period
	|FROM
	|	RegisteredRecordsReservesOfGoodsOfOrganizationsChange AS RegisteredRecordsReservesOfGoodsOfOrganizationsChange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservesOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ReservesOfGoods.Organization AS Organization,
	|	ReservesOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ReservesOfGoods.CCDNumber AS CCDNumber,
	|	ENDOFPERIOD(ReservesOfGoods.Period, MONTH) AS Period,
	|	SUM(ReservesOfGoods.Count) AS Count
	|FROM
	|	AccumulationRegister.CompanySafeStock AS ReservesOfGoods
	|WHERE
	|	(ReservesOfGoods.ItemsLocationAttributes, ReservesOfGoods.Organization, ReservesOfGoods.InventoryOwnerAttribute, ReservesOfGoods.CCDNumber) IN
	|			(SELECT
	|				AnalystTable.ItemsLocationAttributes,
	|				AnalystTable.Organization,
	|				AnalystTable.InventoryOwnerAttribute,
	|				AnalystTable.CCDNumber
	|			FROM
	|				RegisteredRecordsReservesOfGoodsOfOrganizationsChange AS AnalystTable)
	|
	|GROUP BY
	|	ENDOFPERIOD(ReservesOfGoods.Period, MONTH),
	|	ReservesOfGoods.RecordType,
	|	ReservesOfGoods.CCDNumber,
	|	ReservesOfGoods.InventoryOwnerAttribute,
	|	ReservesOfGoods.Organization,
	|	ReservesOfGoods.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(ReservesOfGoods.Count) <> 0
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	CCDNumber,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DimensionCompanySafeStock";
	
	Query.Text = QueryText;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("ToControlBalance", Constants.ControlCompanyStockBalance.Get());
	Query.SetParameter("CalculateChanges_", DocumentsPosting.CalculateChanges_(AdditionalProperties));
	Query.SetParameter("DoNotCheckExcessStorno", AdditionalProperties.Property("DoNotCheckExcessStorno"));
	
	Result = Query.ExecuteBatch();  
	ErrorSampling = Result[1].Select();
	
	ArrayOfExceptionTexts = New Array;
	
	While ErrorSampling.Next() Do
		
		If ErrorSampling.ErrorType = "BalanceError" Then
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: vi phạm cân bằng theo chiều đo %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Hãy liên hệ với nhà phát triển chương trình.';
								|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: нарушен баланс по измерениям %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Обратитесь к разработчикам программы.';
								|en = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: invalid balance by dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.'; fa = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: invalid balance by dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.';
								|it = 'Errore algoritmico in sede di scrittura %Recorder% nel registro %Register%: è stato compromesso l''equilibrio delle dimensioni %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Rivolgetevi ai programmatori.';
								|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: naruszono bilans wymiarów: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Skontaktuj się z twórcami programu.';
								|tr = '%Register%siciline %Recorder% kaydı sırasında algoritma hatası: boyutlara göre bakiye bozuldu %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Program geliştiricisine başvur.'");
		ElsIf ErrorSampling.ErrorType = "ErrorZeroQuantity" Then
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: trong tháng %Month% đã ghi lại số lượng 0 theo chiều đo: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Hãy liên hệ với nhà phát triển chương trình.';
								|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: в месяце %Month% записывается нулевое количество по измерениям: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Обратитесь к разработчикам программы.';
								|en = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: zero quantity is saved for month %Month% for dimensions: %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.'; fa = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: zero quantity is saved for month %Month% for dimensions: %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.';
								|it = 'Errore algoritmico in sede di scrittura %Recorder% nel registro %Register%: nel mese %Month% viene registrato un quantitativo pari a zero per le dimensioni: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Rivolgetevi ai programmatori.';
								|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: w miesiącu %Month% jest zapisywana zerowa ilość wymiarów: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Skontaktuj się z twórcami programu.';
								|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: %Month% ayında boyutlara göre: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber% sıfır değeri kaydediliyor. Program geliştiricisine başvur.'");
		ElsIf ErrorSampling.ErrorType = "InventoryTypeOwnershipError" Then
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: theo chiều đo đã ghi lại dạng vật tư không thuộc sở hữu doanh nghiệp %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Hãy liên hệ với nhà phát triển chương trình.';
								|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: по измерениям записывается вид запасов, не принадлежащий организации %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Обратитесь к разработчикам программы.';
								|en = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: inventory owner attributes that do not belong to the company are saved for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.'; fa = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: inventory owner attributes that do not belong to the company are saved for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.';
								|it = 'Errore algoritmico in sede di scrittura %Recorder% nel registro %Register%: in relazione alle dimensioni viene registrato un genere di scorta non appartenente all''azienda %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Rivolgetevi ai programmatori.';
								|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: dla wymiarów jest zapisywany rodzaj pozycji, nienależący do firmy %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Skontaktuj się z twórcami programu.';
								|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: boyutlara göre iş yerine ait olmayan stok türleri kaydediliyor %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Program geliştiricisine başvur.'");
		ElsIf ErrorSampling.ErrorType = "ErrorInSelectedInventoryType" Then
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: doanh nghiệp và doanh nghiệp trung gian trùng nhau, nhưng khi đó kiểu vật tư của dạng vật tư không phải là %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Hãy liên hệ với nhà phát triển chương trình.';
								|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: организация и кор. организация совпадают, но при этом тип запасов вида запасов не %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Обратитесь к разработчикам программы.';
								|en = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: company and corr. company match but stock type of inventory owner attributes is not %InventoryType% for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.'; fa = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: company and corr. company match but stock type of inventory owner attributes is not %InventoryType% for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.';
								|it = 'Errore algoritmico in sede di scrittura %Recorder% nel registro %Register%: l''azienda e l''azienda di contropartita coincidono, ma la tipologia del genere di scorta non è %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Rivolgetevi ai programmatori.';
								|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: firma i firma kor. zgadzają się ale typ zapasów rodzaju zapasów to nie %InventoryType%%DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Skontaktuj się z twórcami programu.';
								|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: iş yeri ve muhabir iş yeri eşleşiyor, fakat stok türünün stok türü %InventoryType%%DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Program geliştiricisine başvur.'");
		ElsIf ErrorSampling.ErrorType = "ErrorArrivalOfReserveForGoodsInStorageWithRightToSell" Then
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: nhập dự phòng theo kiểu vật tư %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Hãy liên hệ với nhà phát triển chương trình.';
								|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: приход резерва по типу запасов %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Обратитесь к разработчикам программы.';
								|en = 'An algorithmic error occurred when saving %Recorder% to the %Register% register: reserve receipt found by stock type %InventoryType% for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact software developers.'; fa = 'An algorithmic error occurred when saving %Recorder% to the %Register% register: reserve receipt found by stock type %InventoryType% for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact software developers.';
								|it = 'Errore algoritmico in sede di scrittura %Recorder% nel registro %Register%: pervenimento di una riserva relativo alla tipologia di scorta %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Rivolgetevi ai programmatori.';
								|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: wpływ rezerwy wg typu zapasów %InventoryType% %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Skontaktuj się z twórcami programu.';
								|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: yedek girişi stok türün göre %InventoryType%%DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Program geliştiricisine başvur.'");
		ElsIf ErrorSampling.ErrorType = "ProductTypeError" Then
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: ghi lại dự phòng không theo hàng hóa hoặc bao bì luân chuyển theo chiều đo %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Hãy liên hệ với nhà phát triển chương trình.';
								|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: пишется резерв не по товару или многооборотной таре по измерениям %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Обратитесь к разработчикам программы.';
								|en = 'An error occurred in the algorithms while saving %Recorder% to the %Register% register: reserve is saved not for goods or reusable packaging for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.'; fa = 'An error occurred in the algorithms while saving %Recorder% to the %Register% register: reserve is saved not for goods or reusable packaging for dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%. Contact application developers.';
								|it = 'Errore negli algoritmi durante la registrazione %Recorder% nel registro %Register%: le scorte non vengono registrate per merci o imballaggio multiuso per misurazioni %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Contattare sviluppatori del programma.';
								|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: zapisywana jest rezerwa nie dla towaru lub tary wielokrotnego użytku dla wymiarów%DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%. Skontaktuj się z twórcami programu.';
								|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: yedek ürün boyutlara %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber% göre değil veya yeniden kullanılabilir ambalaja göre yazılmıyor. Program geliştiricisine başvur.'");
		Else
			ExceptionText = NStr("vi = 'Lỗi trong thuật toán ghi lại %Recorder% trong biểu ghi %Register%: lỗi chưa phân loại theo chiều đo %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%';
								|ru = 'Ошибка в алгоритмах записи %Recorder% в регистр %Register%: не классифицированная ошибка по измерениям %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%';
								|en = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: unclassified error in dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%'; fa = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: unclassified error in dimensions %DimensionOfProductItem%–%Organization%–%InventoryOwnerAttribute%–%CCDNumber%';
								|it = 'Errore negli algoritmi di registrazione %Recorder% nel registro %Register%: errore non definito per misurazioni %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%';
								|pl = 'Błąd w algorytmach zapisu %Recorder% do rejestru %Register%: niesklasyfikowany błąd wymiarów %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%';
								|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: %DimensionOfProductItem%-%Organization%-%InventoryOwnerAttribute%-%CCDNumber%boyutlara göre sınıflandırılmamış hata'");
		EndIf;

		ExceptionText = StrReplace(ExceptionText, "%Register%", "CompanySafeStock");
		ExceptionText = StrReplace(ExceptionText, "%InventoryType%", "GoodsInStorageWithRightToSell");
		
		InventoriesServer.FillInGeneralParametersForErrorMessagesForOrganizationsProductsAndReserves(
																				ExceptionText,
																				Filter.Recorder.Value,
																				ErrorSampling);
		
		ArrayOfExceptionTexts.Add(ExceptionText);
		
	EndDo;
	
	SamplingByReserves = Result[4].Select();
	
	CurReserve = New Structure("ItemsLocationAttributes, Organization, InventoryOwnerAttribute, CCDNumber, Period");
	UnallocatedStorno = 0;
	
	While SamplingByReserves.Next() Do
		
		If Not TMCommonUseClientServer.StructuresAreEqual(
			SamplingByReserves, 
			CurReserve, 
			"ItemsLocationAttributes,Organization,InventoryOwnerAttribute,CCDNumber") Then
			
			If UnallocatedStorno <> 0 Then
				ExceptionText = NStr("vi = 'Lỗi trong thuật toán khi ghi lại %Recorder% trong biểu ghi %Register%: thực hiện đảo ngược mà không cần dự phòng theo thay đổi: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, đảo ngược thừa %UnallocatedStorno%. Hãy liên hệ với nhà phát triển chương trình.';
									|ru = 'Ошибка в алгоритмах при записи %Recorder% в регистр %Register%: образуется сторно, которое не нужно для покрытия резервов по изменениям: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, лишнее сторно %UnallocatedStorno%. Обратитесь к разработчикам программы.';
									|en = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: the generated storno is not required to cover reserves for changes: %Organization%–%DimensionOfProductItem%–%InventoryOwnerAttribute%–%CCDNumber%. The excessive storno is %UnallocatedStorno%. Contact the application developers.'; fa = 'An algorithmic error occurred while saving %Recorder% to the %Register% register: the generated storno is not required to cover reserves for changes: %Organization%–%DimensionOfProductItem%–%InventoryOwnerAttribute%–%CCDNumber%. The excessive storno is %UnallocatedStorno%. Contact the application developers.';
									|it = 'Errore negli algoritmi durante la registrazione %Recorder% nel registro %Register%: viene formato lo storno che non è necessario per coprire le riserve in base alle modifiche: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% -%CCDNumber%, storno in eccesso %UnallocatedStorno%. Contattare sviluppatori del programma.';
									|pl = 'Błąd w algorytmach przy zapisie %Recorder% do rejestru %Register%: powstaje storno, które nie jest potrzebne do pokrycia rezerw dla wymiarów: %Organization% - %DimensionOfProductItem% - %InventoryOwnerAttribute% - %CCDNumber%, zbędne storno %UnallocatedStorno%. Skontaktuj się z twórcami programu.';
									|tr = '%Register%siciline %Recorder%kaydı sırasında algoritma hatası: değişiklik yedeklerini karşılamak için gerekli olmayan bir iptal oluşur: %Organization%-%DimensionOfProductItem%-%InventoryOwnerAttribute%-%CCDNumber%, ekstra iptal %UnallocatedStorno%. Program geliştiricisine başvur.'");
				ExceptionText = StrReplace(ExceptionText, "%Register%", "CompanySafeStock");
				
				InventoriesServer.FillInGeneralParametersForErrorMessagesForOrganizationsProductsAndReserves(
					ExceptionText,
					Filter.Recorder.Value,
					CurReserve);
				
				ExceptionText = StrReplace(ExceptionText, "%UnallocatedStorno%", UnallocatedStorno);	
				
				ArrayOfExceptionTexts.Add(ExceptionText);
			EndIf;
			
			FillPropertyValues(CurReserve, SamplingByReserves);
			UnallocatedStorno = 0;
			
		EndIf;
		
		If (UnallocatedStorno = 0
			And SamplingByReserves.Count < 0)
			Or UnallocatedStorno < 0 Then
		
			UnallocatedStorno = UnallocatedStorno + SamplingByReserves.Count;
			
			If UnallocatedStorno > 0 Then
				UnallocatedStorno = 0;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ArrayOfExceptionTexts.Count() > 0 Then
		Raise StrConcat(ArrayOfExceptionTexts,Chars.LF);
	EndIf;
	
	If DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		MinimumPeriod = Result[3].Select();
		If MinimumPeriod.Next() Then
			MinimumPeriod = MinimumPeriod.Period;
		Else
			MinimumPeriod = Date('00010101');
		EndIf;
		
		Selection = Result[2].Select();
		DocumentsPosting.RegisterControlTable(
			AdditionalProperties, "RegisteredRecordsReservesOfGoodsOfOrganizationsChange",
			Selection.Next() And Selection.Count > 0, New Structure("MinimumPeriod", MinimumPeriod));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
