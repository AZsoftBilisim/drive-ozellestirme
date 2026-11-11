#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurInitialization;
Var CurContainer; // DataProcessorObject.ExportImportDataContainerManager - container.
Var CurHandlers;
Var CurReplacementDictionaries; // Map - dictionaries of substitutions.

#EndRegion

#Region Internal

Procedure Initialize(Container, Handlers, RefsMap = Undefined) Export
	
	If CurInitialization Then
		
		Raise NStr("vi = 'Đối tượng đã được khởi tạo trước đó.';
					|ru = 'Объект уже был инициализирован ранее.';
					|en = 'The object has already been initialized earlier.'; fa = 'The object has already been initialized earlier.';
					|it = 'L''oggetto è già stato precedentemente inizializzato.';
					|pl = 'Obiekt już był inicjowany wcześniej.';
					|tr = 'Nesne zaten daha önce başlatıldı.'");
		
	EndIf;
		
	CurContainer = Container;
	CurHandlers = Handlers;

	If RefsMap = Undefined Then
		CurReplacementDictionaries = New Map();
	Else
		CurReplacementDictionaries = RefsMap;
	EndIf;
		
	CurInitialization = True;
	
EndProcedure

Function GetInitialParametersInThread() Export
	
	StreamParameters = New Structure();
	StreamParameters.Insert("RefsMap", New FixedMap(RefsMap()));
	
	Return New FixedStructure(StreamParameters);
	
EndFunction

Procedure ReplaceRef(Val XMLTypeName1, Val OldID, Val NewID1, Val OnlyInAbsenceOf = False) Export
	
	If CurReplacementDictionaries.Get(XMLTypeName1) = Undefined Then
		CurReplacementDictionaries.Insert(XMLTypeName1, New Map());
	EndIf;
	
	If OnlyInAbsenceOf Then
		RefsMap = CurReplacementDictionaries.Get(XMLTypeName1);
		If RefsMap.Get(OldID) = Undefined Then
			RefsMap.Insert(OldID, NewID1);
		EndIf;
	Else
		CurReplacementDictionaries.Get(XMLTypeName1).Insert(OldID, NewID1);
	EndIf;
	
EndProcedure

// Replaces links in the file.
//
// Parameters:
//  FileDetails - ValueTableRow - see the variable "Composition" of the module of the unloading processing object of the Manager container.
//
Procedure ReplaceLinksInFile(Val FileDetails) Export
	
	TimeFile = GetTempFileName("xml");
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(TimeFile);
	XMLWriter.WriteXMLDeclaration();
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileDetails.FullName);
	
	ReplaceLinksWhenLoadingFromXML(XMLReader, XMLWriter);
	
	XMLReader.Close();
	XMLWriter.Close();
	
	MoveFile(TimeFile, FileDetails.FullName);
	
EndProcedure

Procedure SaveMatchingLinksToTemporaryStorage(Address) Export
	
	 PutToTempStorage(CurReplacementDictionaries, Address);
	
EndProcedure

Function RefsMap() Export
	
	Return CurReplacementDictionaries;
	
EndFunction


Procedure Close() Export
	
	PerformLinkReplacement();
	CurContainer = Undefined;
	CurReplacementDictionaries = New Map();
	CurInitialization = False;
	
EndProcedure

#EndRegion

#Region Private

// Performs a series of actions to replace links.
//
Procedure PerformLinkReplacement()
	
	FilesTypes = ExportImportDataInternal.FileTypesThatSupportLinkReplacement();
	
	FilesDetails1 = CurContainer.GetFileDescriptionsFromFolder(FilesTypes);
	For Each FileDetails In FilesDetails1 Do
		
		ReplaceLinksInFile(FileDetails);
		
	EndDo;
	
	CurHandlers.WhenReplacingLinks(CurContainer, CurReplacementDictionaries);
	
EndProcedure

Procedure ReplaceLinksWhenLoadingFromXML(XMLReader, XMLWriter)
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			XMLWriter.WriteStartElement(XMLReader.Name);
			
			ValueType = Undefined;
			While XMLReader.ReadAttribute() Do
				
				XMLWriter.WriteAttribute(XMLReader.Name, XMLReader.Value);
				
				If XMLReader.LocalName = "type" And XMLReader.NamespaceURI = "http://www.w3.org/2001/XMLSchema-instance" Then
					Parts = StrSplit(XMLReader.Value, ":");
					If Parts.Count() = 1 Then
						Prefix = "";
						TypeName = Parts[0];
					Else
						Prefix = Parts[0];
						TypeName = Parts[1];
					EndIf;
					If XMLReader.LookupNamespaceURI(Prefix) = "http://v8.1c.ru/8.1/data/enterprise/current-config" Then
						ValueType = TypeName;
					EndIf;
				EndIf;
			EndDo;
			
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			
			NewValue = Undefined;
			
			If ValueType <> Undefined Then
				References = CurReplacementDictionaries.Get(ValueType);
				If References <> Undefined Then
					NewValue = References.Get(XMLReader.Value);
				EndIf;
			EndIf;
			
			If NewValue = Undefined Then
				XMLWriter.WriteText(XMLReader.Value);
			Else
				XMLWriter.WriteText(NewValue);
			EndIf;
			
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
			
			XMLWriter.WriteEndElement();
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Initialize

CurInitialization = False;

#EndRegion

#EndIf