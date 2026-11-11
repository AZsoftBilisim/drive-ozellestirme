#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables


Var CurGraph; // see the New Graph - a table of values that stores the vertices and edges of the graph. 

Var White; // Number - it is used as a constant to denote "white color".

Var Gray; // Number - it is used as a constant to denote "gray color".

Var Black; // Number - it is used as a constant to denote "black color".

#EndRegion

#Region Internal

// Adds a vertex corresponding to the metadata object to the graph.
//
// Parameters:
//  MetadataObjectName - String - name of the metadata object corresponding to the graph vertex being added.
//  OnlyInAbsenceOf - Boolean - if False
//    , an exception will be thrown when trying to add a non-unique value. Otherwise, an attempt to add a non-unique
//    value will be ignored.
//
Procedure AddVertex(Val MetadataObjectName, Val OnlyInAbsenceOf = True) Export
	
	MetadataObject = MetadataObject(MetadataObjectName);
	AlreadyExists = (Vertex(MetadataObject, False) <> Undefined);
	
	If AlreadyExists Then
		
		If OnlyInAbsenceOf Then
			Return;
		Else
			Raise NStr("vi = 'Thử sao chép.';
						|ru = 'Попытка дублирования.';
						|en = 'Duplication attempt.'; fa = 'Duplication attempt.';
						|it = 'Tentativo di duplicazione.';
						|pl = 'Próba powielania.';
						|tr = 'Tekrarlama girişimi.'");
		EndIf;
		
	Else
		
		Count_ = CurGraph; // See NewCount_
		Vertex = Count_.Add(); 
		Vertex.UUID = New UUID;
		Vertex.MetadataObject = MetadataObject;
		Vertex.Ribs = New Array;
		
	EndIf;
	
EndProcedure

// Adds an edge to the graph that connects the vertices.
//
// Parameters:
//  MetadataObjectName1 - MetadataObject - corresponding to the first vertex connected by an edge,
//  MetadataObjectName2 - MetadataObject - corresponding to the second vertex connected by an edge.
//
Procedure AddEdge(Val MetadataObjectName1, Val MetadataObjectName2) Export
	
	MetadataObject1 = MetadataObject(MetadataObjectName1);
	MetadataObject2 = MetadataObject(MetadataObjectName2);
	
	Vertex1 = Vertex(MetadataObject1);
	Vertex2 = Vertex(MetadataObject2);
  
	Vertex1.Ribs.Add(Vertex2.UUID);
	Vertex1.NumberOfEdges = Vertex1.NumberOfEdges + 1;
	
EndProcedure

// Performs topological sorting of graph vertices and returns the result of sorting.
//
// Returns:
//  Array of MetadataObject - an array of metadata objects sorted in such a way that
//    metadata objects corresponding to vertices for which edges were added to other
//    vertices precede in the array before metadata objects corresponding to vertices
//    that were added as edges to other vertices.
//
Function TopologicalSorting() Export
	
	// Initially, all vertices are "white"
	For Each Vertex In CurGraph Do
		Vertex.Color = White;
	EndDo;
	
	SortingResult = New Array();
	
	For Each Vertex In CurGraph Do
		
		// From each vertex we make a detour into the depth
		DepthFirstSearch(Vertex, SortingResult);
		
	EndDo;
	
	Return SortingResult;
	
EndFunction

#EndRegion

#Region Private

// Returns a table of graph values.
// Vertexes are stored as rows in the value table, and edges are stored as the value of one of the columns. 
// 
// Returns:
// 	ValueTable - LongDesc:
//  * UUID - UUID - graph vertex.
//  * MetadataObject - MetadataObject - the metadata object for a vertex of the graph.
//  * Ribs - Array of UUID - array of graph edges. as
//      array elements, values of the unique Identifier type are used, corresponding to rows
//      in the table part that describe other graph vertices.
//  * NumberOfEdges - Number - the number of edges specified for the current vertex.
//  * Color - Number - stores the "color" of the Cur vertex of the graph (see the module area Local variables) .
//
Function NewCount_()

	Count_ = New ValueTable;
	Count_.Columns.Add("UUID", New TypeDescription("UUID"));
	Count_.Columns.Add("MetadataObject");
	Count_.Columns.Add("Ribs", New TypeDescription("Array"));
	Count_.Columns.Add("NumberOfEdges", New TypeDescription("Number"));
	Count_.Columns.Add("Color", New TypeDescription("Number"));
	Count_.Indexes.Add("UUID");
	
	Return Count_;
		
EndFunction

// Returns a metadata object by full name. if the object is not present in the current
// configuration, an exception is thrown.
//
// Parameters:
//  FullName - String - full name of the metadata object.
//
// Returns:
//   MetadataObject - metadata object by full name.
//
Function MetadataObject(Val FullName)
	
	MetadataObject = Metadata.FindByFullName(FullName);
	If MetadataObject = Undefined Then
		
		Raise StrTemplate(NStr("vi = 'Trong cấu hình hiện tại, không có đối tượng metadata %1 hiện có trong tệp dữ liệu.';
								|ru = 'В текущей конфигурации отсутствует объект метаданных %1, присутствующих в файле данных.';
								|en = 'Metadata object %1 existing in the data file is missing in the current configuration.'; fa = 'Metadata object %1 existing in the data file is missing in the current configuration.';
								|it = 'Nella configurazione attuale  manca l''oggetto dei metadati%1, presente nel file dei dati.';
								|pl = 'W obecnej konfiguracji nie ma obiektu metadanych %1 znajdujących się w pliku danych.';
								|tr = 'Geçerli konfigürasyon, veri dosyasında bulunan %1 meta veri nesnesine sahip değil.'"),
			FullName);
		
	EndIf;
	
	Return MetadataObject;
	
EndFunction

// Returns a row in the value table describing the graph that corresponds to the specified
// metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object
//  ExceptionInAbsenceOf - Boolean - flag for generating an exception when the specified
//    metadata object is not present at the vertices of the current graph.
//
// Returns:
//  ValueTableRow - the row of the table of values is the current graph:
//  * UUID - UUID - graph vertex.
//  * MetadataObject - MetadataObject - the metadata object for a vertex of the graph.
//  * Ribs - Array of UUID - array of graph edges.
//  * NumberOfEdges - Number - the number of edges specified for the current vertex.
//  * Color - Number - the color of the Cur vertex of the graph (see the area of the module Local variables) .
//  Undefined - if the specified data object is missing from the Cur graph and the exception is missing = A lie.
//
Function Vertex(Val MetadataObject, Val ExceptionInAbsenceOf = True)
	 
	FilterParameters = New Structure;
	FilterParameters.Insert("MetadataObject", MetadataObject);
	
	Vertexes = CurGraph.FindRows(FilterParameters);

	If Vertexes.Count() = 1 Then
		
		Return Vertexes.Get(0);
		
	ElsIf Vertexes.Count() = 0 Then
		
		If ExceptionInAbsenceOf Then
			
			Raise StrTemplate(NStr("vi = 'Trong cột không có đỉnh đối với đối tượng metadata %1.';
									|ru = 'В графе отсутствует вершина для объекта метаданных %1.';
									|en = 'There is no vertex for the %1 metadata object in the column.'; fa = 'There is no vertex for the %1 metadata object in the column.';
									|it = 'Nel grafico manca il vertice per l''oggetto dei metadati %1.';
									|pl = 'W pozycji brakuje wierzchołka obiektu metadanych %1.';
									|tr = '%1 meta veri nesnesi için grafikte tepe noktası eksik.'"),
				MetadataObject.FullName());
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	Else
		
		Raise StrTemplate(NStr("vi = 'Vi phạm tính đơn trị của cột đối với đối tượng metadata %1.';
								|ru = 'Нарушение уникальности граф для объекта метаданных %1.';
								|en = 'Unique column violation for metadata object %1.'; fa = 'Unique column violation for metadata object %1.';
								|it = 'Violazione dell''unicità del grafico per l''oggetto dei metadati %1.';
								|pl = 'Naruszenie unikalności pozycji dla obiektów metadanych %1.';
								|tr = '%1 meta veri nesnesi için grafik benzersizliği ihlali.'"),
			MetadataObject.FullName());
		
	EndIf;
	
EndFunction

// Performs a depth-first search in topological sorting.
//
// Parameters:
//  Vertex - ValueTableRow - row in the value table current Graph,
//  SortingResult - Array of MetadataObject - the result of the topological sort.
//
Procedure DepthFirstSearch(Vertex, SortingResult)
	
	// If you entered the "gray" vertex, a cycle is found, topological sorting is impossible
	If Vertex.Color = Gray Then
		
		Raise NStr("vi = 'Phụ thuộc đệ quy.';
					|ru = 'Рекурсивная зависимость.';
					|en = 'Recursive dependence.'; fa = 'Recursive dependence.';
					|it = 'Dipendenza ricorsiva.';
					|pl = 'Zależność rekurencyjna.';
					|tr = 'Tekrarlamalı bağımlılık.'");
		
	ElsIf Vertex.Color = White Then
		
		// When entering a vertex, we make it "gray"
		Vertex.Color = Gray;
		
		// From each vertex we make a detour into the depth
		For Each Edge In Vertex.Ribs Do
			DepthFirstSearch(CurGraph.Find(Edge, "UUID"), SortingResult);
		EndDo;
		
		// When leaving the vertex, we make it "black"
		Vertex.Color = Black;
		// And at the same time we put it on the stack
		SortingResult.Add(Vertex.MetadataObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Initialize

CurGraph = NewCount_();

White = 1;
Gray = 2;
Black = 3;

#EndRegion

#EndIf