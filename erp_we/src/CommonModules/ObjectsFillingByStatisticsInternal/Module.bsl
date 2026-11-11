
#Region Internal

// Generates a description of the structure of the details to fill in according to statistics.
//
// Parameters:
//  MetadataObjectName - String - name of the metadata object
//  DetailsToFillIn - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//  SelectionByDetailsToParent - String - the name of the item's details, whose subordinate details must be filled in according to statistics.
//
// Returns:
//  Structure - Properties:
//  	* ObjectAttributes - Structure of KeyAndValue - Properties:
//  		* Key - String - the name of the object's details to be filled in according to statistics
//  		* Value - Structure of KeyAndValue  - Description of "Parent Attributes":
//  			* Key - String - the name of the "parent prop"
//  			* Value - Number - the type of "parent", its impact on the collection of statistics:
//  				1 - "Parent", which must be filled in.
//  					If at least one of the parents of this type is not filled in, it makes no sense to collect statistics of the "subordinate" Attribute.
//  				2 is the "Parent" that should not be filled.
//  					If at least one of the parents of this type is filled in, there is no need to collect statistics of the "subordinate" Attribute.
//  				3 - The "Parent" who always participates in the selection of statistics, regardless of its fullness.
//  					Whether the Attribute of this type is filled in or not, it still participates in the selection of statistics of the "subordinate" Attribute.
//  				4 - The "Parent" who participates in the selection of statistics only if they are filled in.
//  					If this type of Attribute is not filled in, then the statistics of the "subordinate" Attribute are not selected for it.
//  	* ProcedureForFillingInBankingDetails - Array - defines the order of filling in the object's details.
//  		Filling in is performed starting with the details that do not have "parents" and ending with the details that do not have "subordinates".
//  		Array elements are structures whose keys contain the names of the details to be filled in at this step.
//  	* CacheOfPropsValues - Structure of KeyAndValue  - the cached value of the data (used to populate their "subordinates" details)
//  		* Key - String - Name of the item's details
//  		* Value - Arbitrary - value of the item's details
//  	* ErrorText - String - contains the text of an error detected when forming the description of the details structure.
//
Function DescriptionOfItemDetails(MetadataObjectName, DetailsToFillIn, SelectionByDetailsToParent = "") Export
	
	DescriptionOfItemDetails = TemplateForDescribingItemDetails();
	
	AddItemDetailsToDescription(MetadataObjectName, DescriptionOfItemDetails, DetailsToFillIn);
	
	LeaveOnlySubordinateItemDetailsInDescription(DescriptionOfItemDetails, SelectionByDetailsToParent);
	
	DetermineProcedureForFillingInItemDetails(DescriptionOfItemDetails);
	
	Return DescriptionOfItemDetails;
	
EndFunction

// Returns the details of the specified metadata object that are filled in from the object's fill-in data.
//
// Parameters:
//  MetadataObjectName - String - the name of the metadata object.
//
// Returns:
//  Structure - the keys are the names of the metadata object's details.
//
Function DetailsToBeFilledInFromFillingData(MetadataObjectName) Export
	
	AttributesStructure1 = New Structure;
	ObjectMetadata = Metadata.FindByFullName(MetadataObjectName);
	
	For Each Attribute In ObjectMetadata.Attributes Do
		If Attribute.FillFromFillingValue Then
			AttributesStructure1.Insert(Attribute.Name);
		EndIf;
	EndDo;
	
	Return AttributesStructure1;
	
EndFunction

// Defines the value of the props, which according to statistics is "frequency".
//
// Parameters:
//  ObjectReference - DocumentRef - link to the document to be filled in. Can be empty
//  MetadataObjectName - String - name of the metadata object for the first parameter
//  AttributeName - String - name of the object's required information to fill in
//  ParentDetailsValues - Map - selection Attribute values:
//		* Key - String - name of the prop
//		* Value - Arbitrary - the value of the props  	
//  StatisticsCollectionParameters - Structure - See ObjectsFillingByStatistics.NewParametersForCollectingStatistics()
//  ExcludingAuthor - Boolean - True if you do not need to consider the author when determining the value of the Attribute.
//
//  Returns:
//     Arbitrary - the value found by statistics.
//
Function ValueOfPropsForStatistics(
	ObjectReference,
	MetadataObjectName,
	AttributeName,
	ParentDetailsValues,
	StatisticsCollectionParameters,
	ExcludingAuthor = False) Export
		
	FrequencyOfUseOfValue = StatisticsCollectionParameters.FrequencyOfUseOfValue;
	SelectionSize = StatisticsCollectionParameters.SelectionSize;
	
	// Creating the request text (contains templates for replacement)
	// Algorithm for calculating the Attribute value:
	// - select the latest objects by date in the number of "Selection sizes" (except for objects marked for deletion and the Cur object)
	// - let's count the number of times that each value of the Attribute to be filled in was used in the selected objects
	//  	, for example, Value1 = 1 time, Value2 - 3 times, Value3 - 1 time
	// - select one Attribute value whose weight among all values is more than 0.5 (50%)
	//  	for example, weight Value1 = 0.2, weight Value2 = 0.6, weight Value3 = 0.2, i.e. Value2 will be selected
	//  	if there are no values with a suitable weight (> 0.5), then nothing will be selected,
	//  	i.e. no such a Attribute value, which, according to statistical data, is "frequency".
	Query = New Query;
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	&PropsExpression AS AttributeValue
	|FROM
	|	&TableName AS ObjectTable
	|WHERE
	|	NOT ObjectTable.DeletionMark
	|	AND &FilterRef
	|	AND &AdditionalSelection
	|	
	|ORDER BY
	|	ObjectTable.Date DESC";
	
	// Request Selections:
	If ValueIsFilled(ObjectReference) Then 
		// - for the object whose Attributes are filled in according to statistics.
		Query.SetParameter("Ref", ObjectReference);
	EndIf;
	// - by the minimum weight of the value; the weight above this allows you to consider the value "frequency".
	Query.SetParameter("FrequencyOfUseOfValue", FrequencyOfUseOfValue);
	// - by Attributes-parents; request parameters of the form "&Select_<The name of the parent Attribute>".
	FilterConditions = New Array;
	For Each Parent In ParentDetailsValues Do
		If ExcludingAuthor And Parent.Key = "Author" Then 
			Continue;
		EndIf;
		FilterConditions.Add("ObjectTable." + Parent.Key + " = &Filter_" + Parent.Key);
		Query.SetParameter("Filter_" + Parent.Key, Parent.Value);
	EndDo;
	AdditionalSelection = StrConcat(FilterConditions, Chars.LF + Chars.Tab + Chars.Tab + "And" + " ");

	QueryText = StrReplace(QueryText, "ALLOWED TOP 1", "ALLOWED TOP" + " " + Format(SelectionSize, "NG=0"));
	QueryText = StrReplace(QueryText, "&PropsExpression", "ObjectTable." + AttributeName);
	QueryText = StrReplace(QueryText, "&TableName", MetadataObjectName);
	QueryText = StrReplace(QueryText, "&FilterRef", ?(ValueIsFilled(ObjectReference), "NOT ObjectTable.Ref = &Ref", "TRUE"));
	QueryText = StrReplace(QueryText, "&AdditionalSelection", ?(ValueIsFilled(AdditionalSelection), AdditionalSelection, "TRUE"));
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	CommonCount = Selection.Count();
	WeightsOfProps = New Map;
	While Selection.Next() Do
		CurWeight = WeightsOfProps.Get(Selection.AttributeValue);
		If CurWeight = Undefined Then
			CurWeight = 1;
			WeightsOfProps.Insert(Selection.AttributeValue, CurWeight);
		Else
			CurWeight = CurWeight + 1;
			WeightsOfProps.Insert(Selection.AttributeValue, CurWeight);
		EndIf;
		If CurWeight / CommonCount > FrequencyOfUseOfValue Then
			Return Selection.AttributeValue;
		EndIf;
	EndDo;
	
	Return Undefined
	
EndFunction

#EndRegion

#Region Private

// Returns a structure template for describing the object's details.
//
// Returns:
//  Structure -  see the comment to the description of the Session object.
//
Function TemplateForDescribingItemDetails()
	
	DescriptionOfItemDetails = New Structure;
	DescriptionOfItemDetails.Insert("Object",                      New Structure);
	DescriptionOfItemDetails.Insert("ObjectAttributes",            New Structure);
	DescriptionOfItemDetails.Insert("ProcedureForFillingInBankingDetails", New Array);
	DescriptionOfItemDetails.Insert("CacheOfPropsValues",       New Structure);
	DescriptionOfItemDetails.Insert("StatisticsCollectionParameters",    New Structure);
	DescriptionOfItemDetails.Insert("ErrorText",                 "");
	
	Return DescriptionOfItemDetails;
	
EndFunction

#Region FormationOfStructureOfDescriptionOfProps

// Fills in the description of the object's details structure with information about all the object's details.
//
// Parameters:
//  MetadataObjectName - String - name of the metadata object
//  DescriptionOfItemDetails - Structure - see the comment on the description of the Session object
//  DetailsToFillIn - Structure - see the comment to the description of the Session object.
//
Procedure AddItemDetailsToDescription(MetadataObjectName, DescriptionOfItemDetails, DetailsToFillIn)
	
	ObjectMetadata = Metadata.FindByFullName(MetadataObjectName);
	
	For Each DetailsToFillIn_ In DetailsToFillIn Do
		
		If Not Common.HasObjectAttribute(DetailsToFillIn_.Key, ObjectMetadata)
			And Not Common.IsStandardAttribute(ObjectMetadata.StandardAttributes, DetailsToFillIn_.Key) Then
				
			DescriptionOfItemDetails.ErrorText = StrTemplate(
				NStr("vi = 'Trong đối tượng metadata không có mục tin ""%1"".';
					|ru = 'В метаданных объекта нет реквизита ""%1"".';
					|en = 'No attribute ""%1"" in the metadata of the object.'; fa = 'No attribute ""%1"" in the metadata of the object.';
					|it = 'В метаданных объекта нет реквизита ""%1"".';
					|pl = 'W metadanych obiektu nie ma rekwizytu ""%1"".';
					|tr = 'Nesnenin meta verilerinde ""%1"" özniteliği mevcut değil.'"), DetailsToFillIn_.Key);
				
			Return;
		EndIf;
		
		// Let's add the object's details to the description, filled in according to statistics
		DescriptionOfItemDetails.ObjectAttributes.Insert(DetailsToFillIn_.Key, New Structure);
		
		For Each AttributeParent In DetailsToFillIn_.Value Do
			
			If AttributeParent.Key = "StatisticsCollectionParameters" Then
				DescriptionOfItemDetails.StatisticsCollectionParameters.Insert(DetailsToFillIn_.Key,
					AttributeParent.Value);
				Continue;
			EndIf;
			
			If Not Common.HasObjectAttribute(AttributeParent.Key, ObjectMetadata)
				And Not Common.IsStandardAttribute(ObjectMetadata.StandardAttributes, DetailsToFillIn_.Key) Then
					
				DescriptionOfItemDetails.ErrorText = StrTemplate(
					NStr("vi = 'Trong đối tượng metadata không có mục tin ""%1"".';
						|ru = 'В метаданных объекта нет реквизита ""%1"".';
						|en = 'No attribute ""%1"" in the metadata of the object.'; fa = 'No attribute ""%1"" in the metadata of the object.';
						|it = 'В метаданных объекта нет реквизита ""%1"".';
						|pl = 'W metadanych obiektu nie ma rekwizytu ""%1"".';
						|tr = 'Nesnenin meta verilerinde ""%1"" özniteliği mevcut değil.'"), AttributeParent.Key);
					
				Return;
			EndIf;
			
			// Let's add information about the "parent prop" to the description of the object's props filled in according to statistics.
			DescriptionOfItemDetails.ObjectAttributes[DetailsToFillIn_.Key].Insert(
				AttributeParent.Key,
				AttributeParent.Value);
			
		EndDo;
		
		// The author must be taken into account when filling out statistics.
		If Not DescriptionOfItemDetails.ObjectAttributes[DetailsToFillIn_.Key].Property("Author")
			And Common.HasObjectAttribute("Author", ObjectMetadata) Then
			DescriptionOfItemDetails.ObjectAttributes[DetailsToFillIn_.Key].Insert(
				"Author", New Structure("SelectAlways"));
		EndIf;
		
	EndDo;
	
EndProcedure

// Removes "extra" details from the description that are not required to be filled in in this context.
// As a result, in the description of the details, only
// the details that are "subordinate" to the selection requestor or any of its "descendant details"remain.
// 
// Parameters:
//  DescriptionOfItemDetails - Structure - see the comment on the description of the Session object
//  SelectionByDetailsToParent - String - see the comment to the description of the Session object.
//
Procedure LeaveOnlySubordinateItemDetailsInDescription(DescriptionOfItemDetails, SelectionByDetailsToParent)
	
	If Not ValueIsFilled(SelectionByDetailsToParent) // it is required to fill in all the details of the object
		Or ValueIsFilled(DescriptionOfItemDetails.ErrorText) Then
		Return;
	EndIf;
	
	// Let's check that the specified parent is (by "or")
	// - among the details filled in according to statistics
	// - among the details are parents who influence the filling in of other details
	// In fact, this is protection against an incorrect call when a non-existent parent prop is mistakenly passed.
	PropsExist = False;
	
	For Each PropsAndParents In DescriptionOfItemDetails.ObjectAttributes Do
		If Lower(PropsAndParents.Key) = Lower(SelectionByDetailsToParent)
			Or PropsAndParents.Value.Property(SelectionByDetailsToParent) Then
			PropsExist = True;
			Break;
		EndIf;
	EndDo;
	
	If Not PropsExist Then
		DescriptionOfItemDetails.ErrorText = StrTemplate(
			NStr("vi = 'Đối với mục tin ""%1"", chưa xem xét điền theo thống kê.';
				|ru = 'Для реквизита ""%1"" не предусмотрено заполнение по статистике.';
				|en = 'Population by statistics is not supported for the %1"" attribute.'; fa = 'Population by statistics is not supported for the %1"" attribute.';
				|it = 'Для реквизита ""%1"" не предусмотрено заполнение по статистике.';
				|pl = 'Dla atrybutu ""%1"" nie jest przewidziane wypełnienie wg statystyki.';
				|tr = '""%1"" özniteliği, istatistiklere göre doldurulması öngörülmedi.'"),
			SelectionByDetailsToParent);
		Return; // there are no such props
	EndIf;
	
	SubordinateAttributes = New Structure(SelectionByDetailsToParent); // the parent prop and all its "descendant props"
	ContinueSearching      = True;
	
	// We are looking until an idle iteration is performed,
	// at which no new "descendant props" will be found.
	While ContinueSearching Do
		
		ContinueSearching = False;
		
		For Each PropsAndParents In DescriptionOfItemDetails.ObjectAttributes Do
			
			For Each SubordinateAttribute In SubordinateAttributes Do
				
				If PropsAndParents.Value.Property(SubordinateAttribute.Key)
					And Not SubordinateAttributes.Property(PropsAndParents.Key) Then
					
					// Another "descendant Attribute" has been found
					SubordinateAttributes.Insert(PropsAndParents.Key);
					ContinueSearching = True;
					
					Break;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	SubordinateAttributes.Delete(SelectionByDetailsToParent); // the parent Attribute itself does not need to be filled in
	
	// Remove the "extra" details (which are not "descendant details")
	For Each PropsAndParents In DescriptionOfItemDetails.ObjectAttributes Do
		
		If Not SubordinateAttributes.Property(PropsAndParents.Key) Then
			
			// ... from the structure of the object's details
			DescriptionOfItemDetails.ObjectAttributes.Delete(PropsAndParents.Key);
			
		EndIf;
	EndDo;
	
EndProcedure

// Calculates the order in which the object's details should be filled in.
// Details and their relationships are essentially a description of a graph - this procedure performs topological sorting of this graph:
// - first, you must fill in the Bank details, among the "parents" of which there are no other details to fill in
// - then fill in the details that are "subordinate" to the details found in the previous iteration
// - and so on, until the next iteration will not be found any "subordinate" props
// - if a loop is found in the graph, an error will be returned , which means that the description of the object's details was formed incorrectly.
//
// Parameters:
//  DescriptionOfItemDetails - See DescriptionOfItemDetails.
//
Procedure DetermineProcedureForFillingInItemDetails(DescriptionOfItemDetails)
	
	If ValueIsFilled(DescriptionOfItemDetails.ErrorText) Then
		Return;
	EndIf;
	
	DescriptionOfItemDetails.ProcedureForFillingInBankingDetails.Clear();
	
	// Let's imagine all the arcs of the graph in the form of a structure: Key - receiver, Value - source
	IncomingConnections = New Structure;
	
	For Each PropsAndParents In DescriptionOfItemDetails.ObjectAttributes Do
		
		IncomingConnections.Insert(
			PropsAndParents.Key,
			Common.CopyRecursive(PropsAndParents.Value));
		
		For Each Parent In PropsAndParents.Value Do
			If Not IncomingConnections.Property(Parent.Key) Then
				IncomingConnections.Insert(Parent.Key, New Structure);
			EndIf;
		EndDo;
		
	EndDo;
	
	// We continue traversing the graph as long as "unsorted" vertices remain in it.
	While IncomingConnections.Count() > 0 Do
		
		CurLevelDetails = New Structure; // vertices that do not include arcs 
		
		For Each IncomingCommunication In IncomingConnections Do
			If IncomingCommunication.Value.Count() = 0 Then
				// Vertex found without incoming arcs (Attribute without parents)
				CurLevelDetails.Insert(IncomingCommunication.Key);
			EndIf;
		EndDo;
		
		If CurLevelDetails.Count() = 0 Then // a cycle is found in the graph
			DescriptionOfItemDetails.ErrorText = NStr(
				"vi = 'Khi mô tả cấu trúc mục tin để điền theo thống kê
				|cho phép vòng lặp liên kết mục tin';
				|ru = 'При описании структуры реквизитов для заполнения по статистике
				|допущено зацикливание связей реквизитов';
				|en = 'While describing the attribute structure for filling in according to statistics,
				|loop of the attribute links was allowed.'; fa = 'While describing the attribute structure for filling in according to statistics,
				|loop of the attribute links was allowed.';
				|it = 'При описании структуры реквизитов для заполнения по статистике
				|допущено зацикливание связей реквизитов';
				|pl = 'Przy opisie struktury atrybutów do wypełnienia wg statystyki
				|jest dopuszczone zapętnienie połączeń atrybutów';
				|tr = 'İstatistiklere göre doldurulacak özniteliklerin yapısını tanımlarken, öznitelik
				|bağlantılarının döngüye girmesine izin verilir'");
			Return;
		EndIf;
		
		// Let's remove the vertices found on the current iteration without incoming arcs from the graph.
		// As a result, some of their subordinate vertices will now become vertices without incoming arcs.
		For Each CurrentAttribute In CurLevelDetails Do
			IncomingConnections.Delete(CurrentAttribute.Key); // we will remove it from the filled in details
			For Each IncomingCommunication In IncomingConnections Do
				IncomingCommunication.Value.Delete(CurrentAttribute.Key); // we will remove it from the "parent details"
			EndDo;
		EndDo;
		
		// Among those found at the current iteration, we will leave only those details that need to be filled in according to statistics.
		For Each CurrentAttribute In CurLevelDetails Do
			If Not DescriptionOfItemDetails.ObjectAttributes.Property(CurrentAttribute.Key) Then
				// This Attribute is only the "parent", but it is not filled in itself.
				CurLevelDetails.Delete(CurrentAttribute.Key);
			EndIf;
		EndDo;
		
		// If at the current iteration at least one statistically filled in props is found,
		// then we will add a new level to the order of filling in the props.
		// It will contain only the details that are filled in according to statistics, "subordinate" only to the details of higher levels.
		If CurLevelDetails.Count() > 0 Then
			DescriptionOfItemDetails.ProcedureForFillingInBankingDetails.Add(CurLevelDetails);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
