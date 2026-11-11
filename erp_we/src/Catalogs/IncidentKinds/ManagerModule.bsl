#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	Item.PredefinedDataName = "OtherItems";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Phần khác';
																					|ru = 'Прочие';
																					|en = 'Other';
																					|it = 'Altri';
																					|pl = 'Other';
																					|tr = 'Diğer'", LanguagesCodes); // @NStr-2
	Item.Code = "000000001";
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.IncidentKinds - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export

	Return;

EndProcedure

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	Query = New Query(
	"SELECT
	|	IncidentKinds.Ref                      AS Ref,
	|	IncidentKinds.DeletionMark             AS DeletionMark,
	|	REFPRESENTATION(IncidentKinds.Ref) AS Presentation
	|FROM
	|	Catalog.IncidentKinds AS IncidentKinds
	|WHERE
	|	&SearchCriteria_
	|	AND NOT IncidentKinds.DeletionMark");
	
	Query.Text = StrReplace(Query.Text, "&SearchCriteria_", "IncidentKinds.Description LIKE &SearchString");
	Query.SetParameter("SearchString", ?(Parameters.SearchString = Undefined, "", Parameters.SearchString) + "%");
	
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
	Handler.Procedure = "Catalogs.IncidentKinds.FillItemsWithInitialData";
	Handler.Version = "11.5.27.12";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("ce88c062-2d0b-11f1-8de9-0242ac120002");
	Handler.UpdateDataFillingProcedure = "Catalogs.IncidentKinds.RegisterPredefinedItemsToUpdate";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật phần tử định trước.';
							|ru = 'Обновление предопределенных элементов.';
							|en = 'Update predefined items.'; fa = 'Update predefined items.';
							|it = 'Update predefined items.';
							|pl = 'Update predefined items.';
							|tr = 'Önceden tanımlanmış öğelerin güncellenmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.IncidentKinds.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.IncidentKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.IncidentKinds.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterPredefinedItemsToUpdate(Parameters) Export
	
	InfobaseUpdate.RegisterPredefinedItemsToUpdate(
		Parameters,
		Metadata.Catalogs.IncidentKinds);
	
EndProcedure

Procedure FillItemsWithInitialData(Parameters) Export
	
	InfobaseUpdate.FillItemsWithInitialData(
		Parameters,
		Metadata.Catalogs.IncidentKinds);
	
EndProcedure

#EndRegion

#EndIf

#EndRegion