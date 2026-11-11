#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetConditionalAppearance();

	// The report <Data Source report> has a layout <Data Source Name> (for example: LIST2012QU1),
	// the layout <Data Source Name> in the area <Data Source area> 
	// contains the codes and names of the classifier elements,
	// the details of the Data source report and the Data source area are obtained from the parameters
	// Package listname - we take the last layout by default.
	
	CatalogName = Parameters.CatalogName;
	ClassifierParameters = GetLocationOfStatisticsClassifierAndListOfVersions();
	
	AreaDataSource	= ClassifierParameters.AreaDataSource; 
	DataSource			= ClassifierParameters.DataSource; 
	ObjectKind				= ClassifierParameters.ObjectKind;
	VersionsList			= GetVersionsOfReportLists(ObjectKind + "." + DataSource);
	Title				= Metadata.Catalogs[CatalogName].Synonym;
	Pickup					= Parameters.Pickup;
	SelectGroups				= Parameters.SelectGroups;
	
	Items.Classifier.MultipleChoice = Pickup;
	CloseOnChoice = Not Pickup;
	
	If VersionsList.Count() = 0 Then
		
		Cancel = True;
		
		Raise NStr("vi = 'Không thể chọn.
								|Không tìm thấy bảng mã hiệu';
								|ru = 'Невозможно выполнить подбор.
								|Классификатор не найден';
								|en = 'Cannot perform picking.
								|Classifier is not found'; fa = 'Cannot perform picking.
								|Classifier is not found';
								|it = 'Impossibile eseguire la selezione.
								| Classificatore non trovato';
								|pl = 'Wykonanie wyboru nie jest możliwe.
								|Klasyfikator nie został znaleziony';
								|tr = 'Seçim yapılamıyor.
								|Sınıflandırıcı bulunamadı'");
		
	Else
		
		ChoiceList = Items.NameOfTheListLayout.ChoiceList;
		
		For Each Version In VersionsList Do
			ChoiceList.Add(Version.Value, Version.Presentation);
		EndDo;
		
		NameOfTheListLayout = VersionsList[VersionsList.Count() - 1].Value;
		
	EndIf;
	
	FillInClassifier();
	
	If Parameters.ClassifierData Then
		
		DestinationField_ = Items.Purpose;
		DestinationField_.Type = FormFieldType.LabelField;
		DestinationField_.TextColor = StyleColors.LockedAttributeColor;
		
	EndIf;
	
	Items.NameOfTheListLayout.Visible = Not VersionsList.Count() = 1;
	Items.Year.Visible = Not VersionsList.Count() = 1;
	Items.Purpose.Visible = ValueIsFilled(Parameters.Purpose);
	Items.TracedGoods.Visible = DataSource = "FEACN"
												And AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
													Date(1, 1, 1));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameOfTheListLayoutOnChange(Item)
	
	FillInClassifier();
	
EndProcedure

#EndRegion

#Region EventHandlersOfFormClassifierTable

// Called when you double-click or press Enter.
//
&AtClient
Procedure ClassifierSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	AddedNewClassifierElements = False;
	
	SelectedElement = ClassifierSelectionOnServer(RowSelected, AddedNewClassifierElements);
	
	If SelectedElement <> Undefined Then
		NotifyFormAndUserAndClose(SelectedElement, AddedNewClassifierElements);
	EndIf;
	
EndProcedure

// Called when you click the select button.
//
&AtClient
Procedure ClassifierValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	AddedNewClassifierElements = False;
	SelectedElement = ClassifierSelectionOnServer(Value, AddedNewClassifierElements);
	If SelectedElement <> Undefined Then
		NotifyFormAndUserAndClose(SelectedElement, AddedNewClassifierElements);
	EndIf;
	
EndProcedure

// The function processes the data of user's choice.
//
// If the selected elements do not exist in the classifier directory
// they will be added will also be added unit element of the classifier
// in the directory "Classificationinaustralia" if this qualifier is used
// the units and if such units are not in the directory "Classificationinaustralia".
//
// If multiple selections were made, all the selected elements will be processed
// (added to the reference list if missing),
// and an array of references to the elements will be passed to the returned parameter.
//
// Parameters:
// RowsSelected - Array - array of selected rows in the classifier form table;
// AddedNewClassifierElements - Boolean - this flag is set if elements were added to the reference list.
//
// Returns:
// 	- Undefined
//
&AtServer
Function ClassifierSelectionOnServer(Val RowsSelected, AddedNewClassifierElements = False)
	
	ItemRef	= Undefined;
	ReferencesArrray	= New Array;
	
	If TypeOf(RowsSelected) = Type("Array") Then
		
		For Each RowID In RowsSelected Do
			
			Item = Classifier.FindByID(RowID);
			
			If Not ValueIsFilled(Item.Ref) Then
				AddClassifierElement(Item);
				
				AddedNewClassifierElements = True;
			EndIf;
			
			ItemRef = Item.Ref;
			
			ReferencesArrray.Add(Item.Ref);
			
		EndDo;
		
	ElsIf TypeOf(RowsSelected) = Type("Number") Then
		
		Item = Classifier.FindByID(RowsSelected);
		
		If Not ValueIsFilled(Item.Ref) Then
			AddClassifierElement(Item);
			
			AddedNewClassifierElements = True;
		EndIf;
		
		ItemRef = Item.Ref;
		
		ReferencesArrray.Add(Item.Ref);
		
	EndIf;
	
	If Pickup Then
		Return ReferencesArrray;
	Else
		Return ItemRef;
	EndIf;
	
EndFunction

#EndRegion

#Region Private

// Highlights with blue color already selected elements of the classifier.
&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// the presence of the link is highlighted in color
	UOElement = ConditionalAppearance.Items.Add();
	
	ItemField		= UOElement.Fields.Items.Add();
	ItemField.Field	= New DataCompositionField("Classifier");
	
	CommonClientServer.AddCompositionItem(UOElement.Filter,
															"Classifier.ThereIsARef",
															DataCompositionComparisonType.Equal,
															True);
	
	UOElement.Appearance.SetParameterValue("TextColor", StyleColors.FieldSelectionBackColor);
	
	// unit code
	UOElement = ConditionalAppearance.Items.Add();
	
	ItemField 		= UOElement.Fields.Items.Add();
	ItemField.Field 	= New DataCompositionField("UnitOfMeasureCode");
	
	CommonClientServer.AddCompositionItem(UOElement.Filter,
															"Classifier.UnitOfMeasureCode",
															DataCompositionComparisonType.NotFilled);
	
	UOElement.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

// Retrieves previously added directory elements
// 
// Parameters:
// 	CatalogName - String -
// Returns:
// 	ValueTable - table with columns:
// 		* Ref - CatalogRef -
// 		* Code - String -
&AtServerNoContext
Function GetPreviouslyAddedItems(CatalogName)
	
	QueryText =
	"SELECT
	|	CatalogData.Code AS Code,
	|	CatalogData.Ref AS Ref,
	|	&TracedGoods AS TracedGoods
	|FROM
	|	&CatalogTable AS CatalogData";
	
	NameOfTheReferenceTable = Metadata.Catalogs[CatalogName].FullName();
	FieldNameTraceableItem = ?(NameOfTheReferenceTable = Metadata.Catalogs.FEACN.FullName(),
									"CatalogData.TracedGoods",
									"UNDEFINED");
	
	QueryText = StrReplace(QueryText, "&CatalogTable", NameOfTheReferenceTable);
	QueryText = StrReplace(QueryText, "&TracedGoods", FieldNameTraceableItem);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();
	
EndFunction

// Fills the classifier with data
// Parameters:
// - Use the Selection table - Boolean, if true, then the classifier can be filled
//	 using the selection table, and not the entire classifier. 
//
&AtServer
Procedure FillInClassifier(UseSelectionTable = False)
	
	Classifier.Clear();
	
	SetPrivilegedMode(True);
	
	// We get a complete table of classifier elements
	// the table contains the Code and Name of the classifier elements.
	ClassifierElementsFromTemplate = Catalogs[CatalogName].TableOfClassifier(NameOfTheListLayout);
	
	SetPrivilegedMode(False);
	
	// We get a table of classifier elements already available in the directory.
	PreviouslyAddedClassifierElements = GetPreviouslyAddedItems(CatalogName);
	PreviouslyAddedClassifierElements.Indexes.Add("Code, TracedGoods");
	
	ClassifierElements = ClassifierElementsFromTemplate;
	
	If ClassifierElements.Count() = 0 Then
		Return;
	EndIf;
	
	RowFilter = New Structure("Code, TracedGoods");
	
	For Each Item In ClassifierElements Do
		NewRow = Classifier.Add();
		FillPropertyValues(NewRow, Item);
		FillPropertyValues(RowFilter, Item);
		
		FoundItems1 = PreviouslyAddedClassifierElements.FindRows(RowFilter);
		
		If FoundItems1.Count() Then
			NewRow.Ref		= FoundItems1[0].Ref;
			NewRow.ThereIsARef	= True;
		EndIf;
	EndDo;
	
EndProcedure

// Adds a new element to the classifier.
// Parameters:
// - The selected row is a row of the table, the data source for filling in the classifier details.
// 		If there is data about the unit of measurement in the row 
//		, the search is started and the unit of measurement is added.
//
&AtServer
Procedure AddClassifierElement(RowSelected)
	
	CatalogManager		= Catalogs[CatalogName]; // CatalogManagerCatalogName -
	ClassifierElement	= CatalogManager.CreateItem();
	FillPropertyValues(ClassifierElement, RowSelected);
	ClassifierElement.DescriptionFull = RowSelected.Description;
	
	MetadataCatalog = Metadata.Catalogs[CatalogName];
	
	If ValueIsFilled(RowSelected.UnitOfMeasureCode)
		And Common.HasObjectAttribute("UnitOfMeasure", MetadataCatalog) Then
		
		CodeCompliance = Catalogs.PackagesAndUnitsOfMeasure.FillInUnitsFromClassifier(RowSelected.UnitOfMeasureCode);
		ClassifierElement.UnitOfMeasure = CodeCompliance[RowSelected.UnitOfMeasureCode];
		
	EndIf;
	
	ClassifierElement.Write();
	
	RowSelected.Ref = ClassifierElement.Ref;
	
EndProcedure

// Calls a notification about changes to the reference list,
// notifies the user,
// and closes the selection form from the classifier.
//
&AtClient
Procedure NotifyFormAndUserAndClose(SelectedElement, AddedNewClassifierElements = False)
	
	If AddedNewClassifierElements Then
		NotifyChanged(Type("CatalogRef." + CatalogName));
		
		ShowUserNotification(NStr("vi = 'Lưu';
									|ru = 'Сохранение';
									|en = 'Save'; fa = 'ذخیره';
									|it = 'Salvataggio';
									|pl = 'Save';
									|tr = 'Kayıt'"),
										,
										ThisForm.Title,
										PictureLib.Information32);
	EndIf;
	
	NotifyChoice(SelectedElement);
	
EndProcedure

&AtServer
Function GetLocationOfStatisticsClassifierAndListOfVersions()
	
	ClassifierName = CatalogName;
	
	ParametersStructure = New Structure("ObjectKind, DataSource, AreaDataSource");
	
	If ClassifierName = "FEACN" Then
		
		ParametersStructure.Insert("ObjectKind", "Catalog");
		ParametersStructure.Insert("DataSource", "FEACN");
		ParametersStructure.Insert("AreaDataSource", "Rows");
		
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

// The function reads versions of report lists.
//
// Parameters: 
// - Reportname is a string, the ID of the report for which you want to return the versions of the lists.
//
// Returnable Value:
// List of values with report list versions.
//
&AtServer
Function GetVersionsOfReportLists(FullObjectName)
	
	VersionsList = New ValueList;
	
	// We are looking for the transmitted report.
	ObjectMetadata1 = Metadata.FindByFullName(FullObjectName);
	
	If ObjectMetadata1 = Undefined Then
		Return VersionsList;
	EndIf;
	
	For Each CurTemplate In ObjectMetadata1.Templates Do
		
		Template = CurTemplate;
		TemplateName = Template.Name;
		
		If TemplateName = "RNCEA2"
			Or TemplateName = "ClassifierOfCommodityProductsOfForeignEconomicActivity"
			Or TemplateName = "AllRussianProductClassifier" 
			Or TemplateName = "ClassifierOfTypesOfEntrepreneurialActivityPSN" Then
				
			VersionsList.Add(TemplateName, Left(TemplateName, 25));
		
		Else
			
			If VersionsList.Count() > 0 Then
				Break;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return VersionsList;
	
EndFunction

#EndRegion
