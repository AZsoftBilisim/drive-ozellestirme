
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	Classification.ClassificationSection AS Warehouse,
	|	Classification.Characteristic AS Characteristic,
	|	MAX(CASE
	|			WHEN Classification.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Revenue)
	|					AND Classification.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
	|				THEN Classification.Class
	|			ELSE UNDEFINED
	|		END) AS ABCClassRevenue,
	|	MAX(CASE
	|			WHEN Classification.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Revenue)
	|					AND Classification.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ)
	|				THEN Classification.Class
	|			ELSE UNDEFINED
	|		END) AS XYZClassRevenue,
	|	MAX(CASE
	|			WHEN Classification.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.GrossProfit)
	|					AND Classification.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
	|				THEN Classification.Class
	|			ELSE UNDEFINED
	|		END) AS ABCClassGrossProfit,
	|	MAX(CASE
	|			WHEN Classification.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.GrossProfit)
	|					AND Classification.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ)
	|				THEN Classification.Class
	|			ELSE UNDEFINED
	|		END) AS XYZClassGrossProfit,
	|	MAX(CASE
	|			WHEN Classification.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Count)
	|					AND Classification.ClassificationType = VALUE(Enum.TypesOfClassification.ABC)
	|				THEN Classification.Class
	|			ELSE UNDEFINED
	|		END) AS ABCClassQuantity,
	|	MAX(CASE
	|			WHEN Classification.ClassificationParameterType = VALUE(Enum.TypesOfClassificationParameters.Count)
	|					AND Classification.ClassificationType = VALUE(Enum.TypesOfClassification.XYZ)
	|				THEN Classification.Class
	|			ELSE UNDEFINED
	|		END) AS XYZClassQuantity
	|FROM
	|	InformationRegister.ABCXYZInventoryClassification.SliceLast(
	|			,
	|			Products = &Products
	|				AND (ClassificationSection = UNDEFINED
	|					OR VALUETYPE(ClassificationSection) = TYPE(Catalog.Warehouses)
	|						AND ClassificationSection <> VALUE(Catalog.Warehouses.EmptyRef))) AS Classification
	|
	|GROUP BY
	|	Classification.ClassificationSection,
	|	Classification.Characteristic
	|
	|ORDER BY
	|	Warehouse,
	|	Characteristic
	|TOTALS BY
	|	Warehouse");
	
	Query.SetParameter("Products", Parameters.Products);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		AbcxyzclassificationWarehouses = ABCXYZClassification.GetItems();
		
		SampleWarehouse = QueryResult.Select(QueryResultIteration.ByGroups);
		
		While SampleWarehouse.Next() Do
			
			ABCXYZClassificationWarehouse = AbcxyzclassificationWarehouses.Add();
			ABCXYZClassificationWarehouse.Warehouse = SampleWarehouse.Warehouse;
			
			ABCXYZClassificationCharacteristics = ABCXYZClassificationWarehouse.GetItems();
			
			SampleCharacteristics = SampleWarehouse.Select();
			
			AddFeatures = True;
			
			While SampleCharacteristics.Next() Do
				
				If SampleCharacteristics.Count() = 1 And SampleCharacteristics.Characteristic.IsEmpty() Then
					
					AddFeatures = False;
					
				EndIf;
				
				If AddFeatures Then
					
					AbcxyzclassificationCharacteristic = ABCXYZClassificationCharacteristics.Add();
					AbcxyzclassificationCharacteristic.Warehouse = SampleCharacteristics.Characteristic;
					
					AbcxyzclassificationClass = AbcxyzclassificationCharacteristic;
					
				Else
					
					AbcxyzclassificationClass = ABCXYZClassificationWarehouse;
					
				EndIf;
				
				AbcxyzclassificationClass.Revenue = ClassPresentation(SampleCharacteristics.ABCClassRevenue, SampleCharacteristics.XYZClassRevenue);
				AbcxyzclassificationClass.GrossProfit = ClassPresentation(SampleCharacteristics.ABCClassGrossProfit, SampleCharacteristics.XYZClassGrossProfit);
				AbcxyzclassificationClass.Count = ClassPresentation(SampleCharacteristics.ABCClassQuantity, SampleCharacteristics.XYZClassQuantity);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ABCXYZClassificationWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ABCXYZClassification.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Theo tất cả các kho';
													|ru = 'По всем складам';
													|en = 'In all warehouses'; fa = 'در همه انبارها';
													|it = 'Per tutti i magazzini';
													|pl = 'Dla wszystkich magazynów';
													|tr = 'Tüm ambarlara göre'"));

EndProcedure

#Region Other

&AtServer
Function ClassPresentation(ABCClass, XYZClass)
	
	Result = "";
	
	If ABCClass = Enums.ABCClassification.AClass Then
		
		Result = "A";
		
	ElsIf ABCClass = Enums.ABCClassification.BClass Then
		
		Result = "B";
		
	ElsIf ABCClass = Enums.ABCClassification.CClass Or ABCClass = Enums.ABCClassification.NotClassified Then
		
		Result = "C";
		
	EndIf;
	
	If XYZClass = Enums.XYZClassification.XClass Then
		
		Result = Result + "X";
		
	ElsIf XYZClass = Enums.XYZClassification.YClass Then
		
		Result = Result + "Y";
		
	ElsIf XYZClass = Enums.XYZClassification.ZClass Or XYZClass = Enums.XYZClassification.NotClassified Then
		
		Result = Result + "Z";
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
