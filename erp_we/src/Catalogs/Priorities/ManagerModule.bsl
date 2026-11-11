#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
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
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Cao';
																					|ru = 'Высокий';
																					|en = 'High';
																					|it = 'Alto';
																					|pl = 'High';
																					|tr = 'Yüksek'", LanguagesCodes); // @NStr-2
	Item.AddlOrderingAttribute = 1;

	Item = Items.Add();
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Trung bình';
																					|ru = 'Средний';
																					|en = 'Normal';
																					|it = 'Neutro';
																					|pl = 'Normal';
																					|tr = 'Orta'", LanguagesCodes); // @NStr-2
	Item.AddlOrderingAttribute = 2;

	Item = Items.Add();
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thấp';
																					|ru = 'Низкий';
																					|en = 'Low';
																					|it = 'Basso';
																					|pl = 'Low';
																					|tr = 'Düşük'", LanguagesCodes); // @NStr-2
	Item.AddlOrderingAttribute = 3;
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.Priorities - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export

EndProcedure

// Returns the lowest priority.
//
// Returns:
//   - CatalogRef.Priorities -  the lowest priority.
//
Function GetLowerPriority() Export
	
	Result = Catalogs.Priorities.EmptyRef();
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	Priorities.Ref                    AS Priority,
	|	Priorities.AddlOrderingAttribute AS AddlOrderingAttribute
	|FROM
	|	Catalog.Priorities AS Priorities
	|WHERE
	|	NOT Priorities.DeletionMark
	|
	|ORDER BY
	|	AddlOrderingAttribute DESC");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		Result = Selection.Priority;
		
	EndIf;
		
	Return Result;
	
EndFunction

// Returns the highest priority.
//  
// Returns:
//   - CatalogRef.Priorities -  the highest priority.
//
Function GetTopPriority() Export
	
	Result = Catalogs.Priorities.EmptyRef();
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	Priorities.Ref                    AS Priority,
	|	Priorities.AddlOrderingAttribute AS AddlOrderingAttribute
	|FROM
	|	Catalog.Priorities AS Priorities
	|WHERE
	|	NOT Priorities.DeletionMark
	|
	|ORDER BY
	|	AddlOrderingAttribute ASC");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		Result = Selection.Priority;
		
	EndIf;
		
	Return Result;
	
EndFunction

// Gets the priority used for filling in new documents.
//
// Returns:
//  CatalogRef.Priorities - default priority.
//
Function GetDefaultPriority() Export
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	Priorities.Priority                 AS Priority,
		|	Priorities.AddlOrderingAttribute AS AddlOrderingAttribute
		|FROM
		|	(SELECT TOP 2
		|		Priorities.Ref                    AS Priority,
		|		Priorities.AddlOrderingAttribute AS AddlOrderingAttribute
		|	FROM
		|		Catalog.Priorities AS Priorities
		|	WHERE
		|		NOT Priorities.DeletionMark
		|	
		|	ORDER BY
		|		AddlOrderingAttribute DESC) AS Priorities
		|
		|ORDER BY
		|	AddlOrderingAttribute ASC");
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Result = Catalogs.Priorities.EmptyRef();
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Result = Selection.Priority;
	EndIf;
	
	Return Result;
	
EndFunction

// A function for comparing priorities
//
// Parameters:
//  Priority1	 - CatalogRef.Priorities - The first value of the comparison.
//  Priority2	 - CatalogRef.Priorities - The second comparison value.
// 
// Returns:
//   - Number - Result < 0 - the first value is less than the second.
//             Result > 0 - the first value is greater than the second.
//             Result = 0 - the first value is equal to the second.
//
Function ComparePriorities(Priority1, Priority2) Export
	
	Array = New Array;
	Array.Add(Priority1);
	Array.Add(Priority2);
	Result = Common.ObjectsAttributeValue(
		Array,
		"AddlOrderingAttribute");
	Return Result[Priority2] - Result[Priority1];
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	Query = New Query(
	"SELECT
	|	Priorities.Ref                      AS Ref,
	|	Priorities.DeletionMark             AS DeletionMark,
	|	Priorities.AddlOrderingAttribute   AS AddlOrderingAttribute,
	|	REFPRESENTATION(Priorities.Ref) AS Presentation
	|FROM
	|	Catalog.Priorities AS Priorities
	|WHERE
	|	NOT Priorities.DeletionMark
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
