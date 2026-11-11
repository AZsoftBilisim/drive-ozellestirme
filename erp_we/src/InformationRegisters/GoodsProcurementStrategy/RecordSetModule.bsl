#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		
		Return;

	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// In general, the props are additional. the ordering is updated
	UpdatePropsForOrdering = True;
	
	If AdditionalProperties.Property("UpdatePropsForOrdering") Then
		
		UpdatePropsForOrdering = AdditionalProperties.UpdatePropsForOrdering;
		
	EndIf;
	
	// Updating the additional props. ordering
	If UpdatePropsForOrdering Then
	
		// A table of values that stores the maximum values of the additional props. ordering for a combination of warehouse, nomenclature, characteristic.
		ValuesOfDetailsForOrdering = Undefined;
		
		If Count() > 0 Then
			
			// Setting a lock
			SetLock(Filter);
			
			// Processing Set records
			For Each InformationRegisterRecord In ThisObject Do
			
				// The value of the additional props is not set for the record. ordering
				If InformationRegisterRecord.AddlOrderingAttribute = 0 Then
					
					InformationRegisterRecord.AddlOrderingAttribute = NewValueForOrderingProps(InformationRegisterRecord, ValuesOfDetailsForOrdering);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
		
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	// In general, the props are additional. the ordering is updated
	UpdatePropsForOrdering = True;
	
	If AdditionalProperties.Property("UpdatePropsForOrdering") Then
		
		UpdatePropsForOrdering = AdditionalProperties.UpdatePropsForOrdering;
		
	EndIf;
	
	// Updating the additional props. ordering
	If UpdatePropsForOrdering Then
			
		UpdatePropsValuesForOrdering(Filter);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query(
	"SELECT
	|	GoodsProcurementStrategy.Warehouse AS Warehouse,
	|	CAST(GoodsProcurementStrategy.ProcurementStrategy AS Catalog.ProcurementStrategies) AS ProcurementStrategy
	|INTO GoodsProcurementStrategy
	|FROM
	|	&GoodsProcurementStrategy AS GoodsProcurementStrategy
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE AS HasFillingErrors
	|FROM
	|	GoodsProcurementStrategy AS GoodsProcurementStrategy
	|WHERE
	|	GoodsProcurementStrategy.ProcurementStrategy.SupplyType = VALUE(Enum.SupplyTypes.Move)
	|	AND GoodsProcurementStrategy.Warehouse = GoodsProcurementStrategy.ProcurementStrategy.SourceOfDemandSupply");
	
	Query.SetParameter("GoodsProcurementStrategy", Unload());
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		MessageText = NStr("vi = 'Nguồn đảm bảo đã chỉ ra trong phương thức đảm bảo nhu cầu, đối với kiểu đảm bảo ""Điều chuyển nội bộ"" cần khác với kho, mà đã xác định phương án đảm bảo bằng hàng hóa.';
							|ru = 'Источник обеспечения, указанный в способе обеспечения потребностей, для типа обеспечения ""Перемещение"" должен отличаться от склада, для которого определяется вариант обеспечения товарами.';
							|en = 'Source of supply specified in the procurement strategy for the ""Transfer"" supply source type should differ from the warehouse for which goods procurement method is determined.'; fa = 'Source of supply specified in the procurement strategy for the ""Transfer"" supply source type should differ from the warehouse for which goods procurement method is determined.';
							|it = 'La fonte di approvvigionamento indicata nel metodo di soddisfazione della domanda per il tipo di approvvigionamento ""Trasferimento"" deve distinguersi dal magazzino per il quale viene definita la versione di approvvigionamento delle merci.';
							|pl = 'Źródło zaopatrzenia, określone w sposobie zaopatrzenia potrzeb, dla rodzaju zaopatrzenia ""Przeniesienie"" musi różnić się od magazynu, dla którego ustalana jest opcja dostarczenia towarów.';
							|tr = '""Transfer"" tedarik türü için talebi karşılama yönteminde belirtilen tedarik kaynağı, ürün tedarik seçeneğinin tanımlandığı ambardan farklı olmalıdır.'");
		CommonClientServer.MessageToUser(MessageText,, "ProcurementStrategy",, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Function NewValueForOrderingProps(InformationRegisterRecord, ValuesOfDetailsForOrdering)
	
	AddlOrderingAttribute = 1;
	
	// Creating a table of values that stores the maximum values of the additional props. ordering for a combination of warehouse,
	// nomenclature, characteristic.
	If ValuesOfDetailsForOrdering = Undefined Then
		
		ValuesOfDetailsForOrdering = New ValueTable;
		ValuesOfDetailsForOrdering.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		ValuesOfDetailsForOrdering.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		ValuesOfDetailsForOrdering.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		ValuesOfDetailsForOrdering.Columns.Add("AddlOrderingAttribute", New TypeDescription("Number"));
		
	EndIf;
	
	// Search for the value of the additional details. ordering
	FoundRows = ValuesOfDetailsForOrdering.FindRows(New Structure("Warehouse, Products, Characteristic", InformationRegisterRecord.Warehouse, InformationRegisterRecord.Products, InformationRegisterRecord.Characteristic));
	
	If FoundRows.Count() > 0 Then
		
		AddlOrderingAttribute = FoundRows[0].AddlOrderingAttribute + 1;
		FoundRows[0].AddlOrderingAttribute = AddlOrderingAttribute;
		
	Else
		
		NewRow = ValuesOfDetailsForOrdering.Add();
		
		NewRow.Warehouse = InformationRegisterRecord.Warehouse;
		NewRow.Products = InformationRegisterRecord.Products;
		NewRow.Characteristic = InformationRegisterRecord.Characteristic;
		
		Query = New Query(
		"SELECT TOP 1
		|	GoodsProcurementStrategy.AddlOrderingAttribute AS AddlOrderingAttribute
		|FROM
		|	InformationRegister.GoodsProcurementStrategy AS GoodsProcurementStrategy
		|WHERE
		|	GoodsProcurementStrategy.Warehouse = &Warehouse
		|	AND GoodsProcurementStrategy.Products = &Products
		|	AND GoodsProcurementStrategy.Characteristic = &Characteristic
		|
		|ORDER BY
		|	AddlOrderingAttribute DESC");
		
		Query.SetParameter("Warehouse", InformationRegisterRecord.Warehouse);
		Query.SetParameter("Products", InformationRegisterRecord.Products);
		Query.SetParameter("Characteristic", InformationRegisterRecord.Characteristic);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		If ValueIsFilled(Selection.AddlOrderingAttribute) Then
			
			AddlOrderingAttribute = Selection.AddlOrderingAttribute + 1;
			
		EndIf;
		
		NewRow.AddlOrderingAttribute = AddlOrderingAttribute;
		
	EndIf;
		
	Return AddlOrderingAttribute;
	
EndFunction

Procedure UpdatePropsValuesForOrdering(FilterParameters)
	
	// Setting a lock
	SetLock(FilterParameters);
	
	Query = New Query(
	"SELECT
	|	GoodsProcurementStrategy.Warehouse AS Warehouse,
	|	GoodsProcurementStrategy.Products AS Products,
	|	GoodsProcurementStrategy.Characteristic AS Characteristic,
	|	GoodsProcurementStrategy.ProcurementStrategy AS ProcurementStrategy,
	|	GoodsProcurementStrategy.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	CASE
	|		WHEN (GoodsProcurementStrategy.Warehouse = &Warehouse
	|				OR (NOT &WarehouseUse))
	|				AND (GoodsProcurementStrategy.Products = &Products
	|					OR (NOT &NomenclatureUsage))
	|				AND (GoodsProcurementStrategy.Characteristic = &Characteristic
	|					OR (NOT &CharacteristicUse))
	|				AND (GoodsProcurementStrategy.ProcurementStrategy = &ProcurementStrategy
	|					OR (NOT &WayToEnsureNeedsOfUse))
	|			THEN 0
	|		ELSE 1
	|	END AS Priority
	|FROM
	|	InformationRegister.GoodsProcurementStrategy AS GoodsProcurementStrategy
	|WHERE
	|	(GoodsProcurementStrategy.Warehouse = &Warehouse
	|			OR (NOT &WarehouseUse))
	|	AND (GoodsProcurementStrategy.Products = &Products
	|			OR (NOT &NomenclatureUsage))
	|	AND (GoodsProcurementStrategy.Characteristic = &Characteristic
	|			OR (NOT &CharacteristicUse))
	|
	|ORDER BY
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	AddlOrderingAttribute,
	|	Priority");
	
	Query.SetParameter("Warehouse", FilterParameters.Warehouse.Value);
	Query.SetParameter("WarehouseUse", FilterParameters.Warehouse.Use);
	Query.SetParameter("Products", FilterParameters.Products.Value);
	Query.SetParameter("NomenclatureUsage", FilterParameters.Products.Use);
	Query.SetParameter("Characteristic", FilterParameters.Characteristic.Value);
	Query.SetParameter("CharacteristicUse", FilterParameters.Characteristic.Use);
	Query.SetParameter("ProcurementStrategy", FilterParameters.ProcurementStrategy.Value);
	Query.SetParameter("WayToEnsureNeedsOfUse", FilterParameters.ProcurementStrategy.Use);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		OrderingAttributeValues = 0;
		PreviousRecord = New Structure("Warehouse, Products, Characteristic");
		
		// Creating a recordset
		RecordSet = InformationRegisters.GoodsProcurementStrategy.CreateRecordSet();
		
		// Setting selections
		RecordSet.Filter.Warehouse.Value = FilterParameters.Warehouse.Value;
		RecordSet.Filter.Warehouse.Use = FilterParameters.Warehouse.Use;
		RecordSet.Filter.Products.Value = FilterParameters.Products.Value;
		RecordSet.Filter.Products.Use = FilterParameters.Products.Use;
		RecordSet.Filter.Characteristic.Value = FilterParameters.Characteristic.Value;
		RecordSet.Filter.Characteristic.Use = FilterParameters.Characteristic.Use;
		
		// Setting additional properties
		RecordSet.AdditionalProperties.Insert("UpdatePropsForOrdering", False);
		
		// Sample Processing
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			// The entry does not differ from the previous one
			If Selection.Warehouse = PreviousRecord.Warehouse And Selection.Products = PreviousRecord.Products And Selection.Characteristic = PreviousRecord.Characteristic Then
				
				// The following ordering value
				OrderingAttributeValues = OrderingAttributeValues + 1;
				
			Else
				
				// Saving the current record
				FillPropertyValues(PreviousRecord, Selection);
				OrderingAttributeValues = 1;
				
			EndIf;
			
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			NewRecord.AddlOrderingAttribute = OrderingAttributeValues;
			
		EndDo;
		
		RecordSet.Write(True);
		
	EndIf;
	
EndProcedure

Procedure SetLock(FilterParameters)
	
	DataLock = New DataLock;
			
	LockItem = DataLock.Add("InformationRegister.GoodsProcurementStrategy");
	LockItem.Mode = DataLockMode.Exclusive;
	
	If FilterParameters.Warehouse.Use Then
		
		LockItem.SetValue("Warehouse", FilterParameters.Warehouse.Value);
		
	EndIf;
	
	If FilterParameters.Products.Use Then
		
		LockItem.SetValue("Products", FilterParameters.Products.Value);
		
	EndIf;
	
	If FilterParameters.Characteristic.Use Then
		
		LockItem.SetValue("Characteristic", FilterParameters.Characteristic.Value);
		
	EndIf;
	
	DataLock.Lock();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf