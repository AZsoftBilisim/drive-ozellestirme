
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Tree = Catalogs.PackagesAndUnitsOfMeasure.GetClassifierData();
	
	Tree.Columns.Add("Check",    New TypeDescription("Boolean"));
	Tree.Columns.Add("Exists", New TypeDescription("Boolean"));
	
	Map = New Map;
	Query = New Query;
	Query.Text = 
	"SELECT
	|	UnitsOfMeasurement.Ref AS Ref,
	|	UnitsOfMeasurement.Code AS Code
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS UnitsOfMeasurement
	|WHERE
	|	UnitsOfMeasurement.Code <> """"
	|	AND (UnitsOfMeasurement.MeasuredValueType IN (&Filter)
	|			OR NOT &FilterFilledIn_)";
	Filter = Undefined;
	Parameters.Property("Filter", Filter);
	Query.SetParameter("Filter", Filter);
	Query.SetParameter("FilterFilledIn_", ValueIsFilled(Filter));
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Map.Insert(TrimAll(Selection.Code), Selection.Ref);
	EndDo;
	
	ProcessTree(Tree, Filter, Map);
	
	UnitCompliance = New FixedMap(Map);
	
	ValueToFormAttribute(Tree, "ClassifierTree");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersClassifierTree

&AtClient
Procedure TraversingTreeUpwards(CurrentData)
	
	Parent = CurrentData.GetParent();
	
	If Parent <> Undefined Then // Top level
		ChildLines = Parent.GetItems();
		
		CommonCount		= 0;
		SelectedCount	= 0;
		
		For Each Item In ChildLines Do
			CommonCount = CommonCount + 1;
			
			If Item.Exists Then
				Continue;
			EndIf;
			
			If Item.Check = 2 Then
				SelectedCount = SelectedCount + 0.5;
			ElsIf Item.Check = 1 Then
				SelectedCount = SelectedCount + 1;
			EndIf;
		EndDo;
		
		If CommonCount = SelectedCount Then
			Parent.Check = 1;
		ElsIf SelectedCount = 0 Then
			Parent.Check = 0;
		Else
			Parent.Check = 2;
		EndIf;
		
		TraversingTreeUpwards(Parent);
	EndIf;
	
EndProcedure

&AtClient
Procedure TraversingTreeDownwards(CurrentData)
	
	ChildLines = CurrentData.GetItems();
	
	For Each Item In ChildLines Do
		If Item.Exists Then
			Continue;
		EndIf;
		
		Item.Check = CurrentData.Check;
		
		TraversingTreeDownwards(Item);
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckOnChange(CurrentData)
	
	If CurrentData.Check = 2 Then
		CurrentData.Check = 0;
	EndIf;
	
	TraversingTreeUpwards(CurrentData);
	TraversingTreeDownwards(CurrentData);
	
EndProcedure

&AtClient
Procedure ClassifierTreeCheckOnChange(Item)
	
	CurrentData = Items.ClassifierTree.CurrentData;
	CheckOnChange(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportData(Command)
	
	SelectionProcessingCompleted = True;
	CalculationResult1 = ProcessSelectionResultsOnServer(SelectionProcessingCompleted);
	
	If SelectionProcessingCompleted Then
		Close(CalculationResult1);
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTreeNumericCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTreeSymbolNational.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTreeInternationalSymbol.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTreeCodeLetterDesignationNational.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTreeCodeLetterDesignationInternational.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClassifierTree.NumericCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClassifierTree.NumericCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ClassifierTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ClassifierTree.Exists");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

#Region Other

&AtServer
Function ProcessSelectionResultsOnServer(SelectionProcessingCompleted)
	
	NumberOfNewItems_ = 0;
	ArrayOfNewElements     = New Array;
	
	Tree = FormAttributeToValue("ClassifierTree");
	
	BeginTransaction();
	
	Try
		
		UnitMatchingData = UnitCompliance; // FixedMap - 
		
		For Each LineLevel1 In Tree.Rows Do
			If LineLevel1.Check Then
				For Each LineLevel2 In LineLevel1.Rows Do
					If LineLevel2.Check Then
						For Each LineLevel3 In LineLevel2.Rows Do
							If LineLevel3.Check Then
								
								NewUnitOfMeasure = False;
								UnitReference         = UnitMatchingData.Get(TrimAll(LineLevel3.NumericCode));
								
								If UnitReference <> Undefined Then
									CatalogObject = UnitReference.GetObject();
									If Not CatalogObject.Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure Then
										Continue;
									EndIf;
								Else
									NewUnitOfMeasure = True;
									CatalogObject = Catalogs.PackagesAndUnitsOfMeasure.CreateItem();
									CatalogObject.Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure;
								EndIf;
								
								If ValueIsFilled(LineLevel3.SymbolNational) Then
									Description = LineLevel3.SymbolNational;
								ElsIf ValueIsFilled(LineLevel3.InternationalSymbol) Then
									Description = LineLevel3.InternationalSymbol;
								ElsIf ValueIsFilled(LineLevel3.CodeLetterDesignationNational) Then
									Description = LineLevel3.CodeLetterDesignationNational;
								ElsIf ValueIsFilled(LineLevel3.CodeLetterDesignationInternational) Then
									Description = LineLevel3.CodeLetterDesignationInternational;
								Else
									Description = LineLevel3.Description;
								EndIf;
								
								CatalogObject.Description            = StrReplace(Description,Chars.LF,"/");
								CatalogObject.InternationalAbbreviation = StrReplace(LineLevel3.CodeLetterDesignationInternational,Chars.LF,"/");
								CatalogObject.DescriptionFull      = StrReplace(LineLevel3.Description,Chars.LF,"/");
								CatalogObject.Code                     = TrimAll(LineLevel3.NumericCode);
								CatalogObject.Numerator               = LineLevel3.Numerator;
								CatalogObject.Denominator             = LineLevel3.Denominator;
								
								If ValueIsFilled(LineLevel3.MeasuredValueType) Then
									CatalogObject.MeasuredValueType = Enums.TypesOfMeasuredValues[LineLevel3.MeasuredValueType];
								EndIf;
								
								CatalogObject.Write();
								
								If NewUnitOfMeasure Then
									NumberOfNewItems_ = NumberOfNewItems_ + 1;
									
									ArrayOfNewElements.Add(CatalogObject.Ref);
								EndIf;
								
							EndIf;
						EndDo;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		If NumberOfNewItems_ = 0 Then
			SelectionProcessingCompleted = False;
		EndIf;
				
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		NumberOfNewItems_  = 0;
		SelectionProcessingCompleted = False;
		
		MessageText = NStr("vi = 'Không thể chọn đơn vị đo từ bộ phân loại.';
							|ru = 'Не удалось подобрать единицу измерения из классификатора.';
							|en = 'Cannot pick UOM from the classifier.'; fa = 'Cannot pick UOM from the classifier.';
							|it = 'Non è stato possibile selezionare l''unità di misura dal classificatore.';
							|pl = 'Nie udało się wybrać jednostki miary z klasyfikatora.';
							|tr = 'Sınıflandırıcıdan bir ölçü birimi seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText);
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode(); // To record an event in the registration Log.
		WriteLogEvent(NStr("vi = 'Lựa chọn đơn vị tính từ bảng phân loại.';
							|ru = 'Подбор единиц измерения из классификатора.';
							|en = 'Pick UOM from the classifier.'; fa = 'Pick UOM from the classifier.';
							|it = 'Selezione delle unità di misura dal classificatore.';
							|pl = 'Wybór jednostki miary z klasyfikatora.';
							|tr = 'Sınıflandırıcıdan ölçü birimlerinin seçimi.'", DefaultLanguageCode),
			EventLogLevel.Error, , ,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	CalculationResult1 = New Structure("NumberOfNewItems_, NewItems", NumberOfNewItems_,
		ArrayOfNewElements);
	
	Return CalculationResult1;
	
EndFunction

&AtServer
Procedure ProcessTree(Tree, Filter, Map)
	
	ArrayToDelete = New Array;
	ProcessLevel(Tree.Rows, Filter, ArrayToDelete, Map, 1);
	RemoveRowsFromRowCollection(Tree.Rows, ArrayToDelete);
		
EndProcedure

&AtServer
Procedure ProcessLevel(Rows, Filter, ArrayToDelete, Map, Level)
	
	For Each String In Rows Do
		If Level = 3 Then
			
			TypeOfCurLine = Enums.TypesOfMeasuredValues.EmptyRef();
			If ValueIsFilled(String.MeasuredValueType) Then 
				TypeOfCurLine = Enums.TypesOfMeasuredValues[String.MeasuredValueType];
			EndIf;

			If TypeOf(Filter) = Type("Array") And ValueIsFilled(Filter) And Filter.Find(TypeOfCurLine) = Undefined Then
				ArrayToDelete.Add(String);
			Else
				If Map.Get(String.NumericCode) <> Undefined Then
					String.Exists = True;
					String.Check    = True;
				EndIf;
			EndIf;
			
		Else
			PrepareToRemoveNextLevel = New Array;
			ProcessLevel(String.Rows, Filter, PrepareToRemoveNextLevel, Map, Level + 1);
			RemoveRowsFromRowCollection(String.Rows, PrepareToRemoveNextLevel);
			If String.Rows.Count() = 0 Then
				ArrayToDelete.Add(String);	
			EndIf;                
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure RemoveRowsFromRowCollection(Rows, ArrayToDelete)
	For Each RowToDelete In ArrayToDelete Do
		Rows.Delete(RowToDelete);
	EndDo;
EndProcedure

#EndRegion

#EndRegion
