#Region Public

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add();
	Item.PredefinedDataName = "High";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Cao';
																					|ru = 'Высокая';
																					|en = 'High';
																					|it = 'Alta';
																					|pl = 'High';
																					|tr = 'Yüksek'", LanguagesCodes); // @NStr-2
	Item.AddlOrderingAttribute = 1;
	Item.Code = "000000001";

	Item = Items.Add();
	Item.PredefinedDataName = "Medium";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trung bình';
																					|ru = 'Средняя';
																					|en = 'Average';
																					|it = 'Media';
																					|pl = 'Average';
																					|tr = 'Ortalama'", LanguagesCodes); // @NStr-2
	Item.AddlOrderingAttribute = 2;
	Item.Code = "000000002";

	Item = Items.Add();
	Item.PredefinedDataName = "Low";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thấp';
																					|ru = 'Низкая';
																					|en = 'Low';
																					|it = 'Bassa';
																					|pl = 'Low';
																					|tr = 'Düşük'", LanguagesCodes); // @NStr-2
	Item.AddlOrderingAttribute = 3;
	Item.Code = "000000003";
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.IncidentsSeverity - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export

	Return;

EndProcedure

// Adds a conditional design for the Event Criticality field to the list form.
//
// Parameters:
//  Form             - ClientApplicationForm - shape.
//  ListName         - String - name of the dynamic list.
//  FieldName           - String - the name of the criticality field of the dynamic list incidents.
//  TagName       - String - the name of the criticality column of the dynamic list incidents.
//  SelectionIsUsed_ - Boolean - True if the selection is used and you need to set a conditional design for it.
//  FilterFieldName     - String - name of the selection form details.
//  FilterElementName - String - name of the form element to select.
//
Procedure SetConditionalDesignOfCriticalityField(Form, ListName, FieldName, TagName, SelectionIsUsed_ = False, FilterFieldName = Undefined, FilterElementName = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	
	PresentationOfDesignElement = NStr("vi = 'Mức độ nghiêm trọng';
										|ru = 'Критичность';
										|en = 'Severity'; fa = 'شدت';
										|it = 'Criticità';
										|pl = 'Krytyczność';
										|tr = 'Önem derecesi'");
	For IndexOf = 0 To ConditionalAppearance.Items.Count() - 1 Do
		Item = ConditionalAppearance.Items[0];
		If Item.Presentation = PresentationOfDesignElement Then
			ConditionalAppearance.Items.Delete(Item);
			IndexOf = IndexOf - 1;
		EndIf;
	EndDo;
	
	Query = New Query(
		"SELECT
		|	IncidentsSeverity.Ref  AS Severity,
		|	IncidentsSeverity.Color    AS Color
		|FROM
		|	Catalog.IncidentsSeverity AS IncidentsSeverity");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			Color = Selection.Color;// ValueStorage
			
			// Column
			Item = ConditionalAppearance.Items.Add();
			
			Item.Fields.Items.Add().Field = New DataCompositionField(TagName);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(ListName + "." + FieldName);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Selection.Severity;
			
			Item.Appearance.SetParameterValue("TextColor", Color.Get());
			
			Item.Presentation = PresentationOfDesignElement;
			
			// Filter
			If SelectionIsUsed_ Then
				
				Item = ConditionalAppearance.Items.Add();
				
				Item.Fields.Items.Add().Field = New DataCompositionField(FilterElementName);
				
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField(FilterFieldName);
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Selection.Severity;
				
				Item.Appearance.SetParameterValue("TextColor", Color.Get());
				
				Item.Presentation = PresentationOfDesignElement;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndIf

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	Query = New Query(
	"SELECT
	|	IncidentsSeverity.Ref                      AS Ref,
	|	IncidentsSeverity.DeletionMark             AS DeletionMark,
	|	IncidentsSeverity.AddlOrderingAttribute   AS AddlOrderingAttribute,
	|	REFPRESENTATION(IncidentsSeverity.Ref) AS Presentation
	|FROM
	|	Catalog.IncidentsSeverity AS IncidentsSeverity
	|WHERE
	|	NOT IncidentsSeverity.DeletionMark
	|
	|ORDER BY
	|	AddlOrderingAttribute");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
	
		While Selection.Next() Do
		
			ChoiceData.Add(Selection.Ref, Selection.Presentation);
		
		EndDo;
		
	EndIf;
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.IncidentsSeverity.FillItemsWithInitialData";
	Handler.Version = "11.5.27.12";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("b90702a8-2d0b-11f1-8de9-0242ac120002");
	Handler.UpdateDataFillingProcedure = "Catalogs.IncidentsSeverity.RegisterPredefinedItemsToUpdate";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật phần tử định trước.';
							|ru = 'Обновление предопределенных элементов.';
							|en = 'Update predefined items.'; fa = 'Update predefined items.';
							|it = 'Update predefined items.';
							|pl = 'Update predefined items.';
							|tr = 'Önceden tanımlanmış öğelerin güncellenmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.IncidentsSeverity.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.IncidentsSeverity.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.IncidentsSeverity.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterPredefinedItemsToUpdate(Parameters) Export
	
	InfobaseUpdate.RegisterPredefinedItemsToUpdate(
		Parameters,
		Metadata.Catalogs.IncidentsSeverity);
	
EndProcedure

Procedure FillItemsWithInitialData(Parameters) Export
	
	InfobaseUpdate.FillItemsWithInitialData(
		Parameters,
		Metadata.Catalogs.IncidentsSeverity);
	
EndProcedure

#EndRegion

#EndIf

#EndRegion

