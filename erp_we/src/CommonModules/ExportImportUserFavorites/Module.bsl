////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region RegisteringDataUploadAndDownloadHandlers

// Called when registering custom data upload handlers.
//
// Parameters:
//  HandlersTable - ValueTable - In this procedure, it is required
//    to supplement this table of values with information about registered arbitrary
//    data upload handlers. 
//    Columns:
//    * MetadataObject - MetadataObject - when unloading the data of which
//      the registered handler should be called,
//    * Handler - CommonModule - a General module that implements an arbitrary
//      data upload handler. The set of export procedures to
//      be implemented in the handler depends on setting the values of the following
//      columns in the value table,
//    * Version - String - version number of the data upload / download handler interface
//      supported by the handler,
//    * BeforeUnloadingType - Boolean -  flag of the need to call the handler before
//      unloading all information database objects related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure can be implemented before loading the type(),
//      which supports the following parameters:
//      * Container - DataProcessorObject.ExportImportDataContainerManager - 
//          the container manager used in the data upload process. For more information, see the comment
//          on the software interface for processing the unloading of the Manager container,
//      * Serializer - XDTOSerializer - initialized with support
//          for link annotation execution. If
//          additional data needs to be unloaded in an arbitrary upload handler, you should use
//          The serializer XDTO passed to the procedure before loading the type() as
//          the value of the Serializer parameter, and not obtained using the global
//          context property Serializer XDTO,
//      * MetadataObject - MetadataObject - before unloading the data of which
//          the handler was called,
//      * Cancel - Boolean - if the value
//          of this parameter is set to True in the Preload Type() procedure, the objects corresponding
//          to the current metadata object will not be unloaded.
//    * BeforeExportObject - Boolean - flag for whether a handler should be called before
//      uploading a specific database object. If the value is assigned
//      True - the exported procedure must be implemented in the general handler module
//      Before loading an object() that supports the following parameters:
//      * Container - DataProcessorObject.ExportImportDataContainerManager - 
//          the container manager used in the data upload process. For more information, see the comment
//          on the software interface for processing the unloading of the Manager container,
//      * ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//          manager for unloading the current object. For more information, see the comment on the processing software interface
//          Unloading and unloading of the given management and unloading of the given information database. The parameter is passed only when calling
//          handler procedures for which a version not lower than 1.0.0.1 is specified during registration,
//      * Serializer - XDTOSerializer - initialized with support
//          for link annotation execution. If
//          additional data needs to be unloaded in an arbitrary upload handler, you should use
//          The serializer XDTO passed to the procedure before loading the object() as
//          the value of the Serializer parameter, and not obtained using the global
//          context property Serializer XDTO,
//      * Object - ConstantValueManager, CatalogObject, DocumentObject -
//               - BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject -
//               - ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//               - AccumulationRegisterRecordSet, AccountingRegisterRecordSet - 
//               - CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          the data object of the information database, before unloading which the handler was called.
//          The value passed to the procedure before loading the object() as the parameter value
//          The object can be modified inside the handler before loading the object(), and the
//          changes made will be reflected in the serialization of the object in the unloading files, but
//          will not be recorded in the information database.
//      * Artifacts - Array of XDTODataObject - a set of additional information that is logically inextricably
//          linked to the object, but is not part of it (artifacts of the object). Artifacts must
//          be generated inside the handler before loading the object() and added to the array passed
//          as the value of the Artifacts parameter. Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem. In the future
//          , the artifacts generated in the procedure before loading the object() will be available in the procedures
//          of the data loading processors (see the comment on the procedure for registering the Data loading processors().
//      * Cancel - Boolean - if the value
//           of this parameter is set to True in the procedure before loading an Object (), the object for which the handler was called
//           will not be unloaded.
//    * AfterUnloadingType - Boolean - flag of the need to call the handler after unloading all
//      information database objects related to this metadata object. If the value is assigned
//      True - the exported procedure must be implemented in the general handler module
//      Post-loading type() that supports the following parameters:
//      * Container - DataProcessorObject.ExportImportDataContainerManager - 
//          the container manager used in the data upload process. For more information, see the comment
//          on the software interface for processing the unloading of the Manager container,
//      * Serializer - XDTOSerializer - initialized with support for executing
//          link annotations. If you need
//          to upload additional data in an arbitrary upload handler, use
//          Serializatorxdto passed to the post-load Type () procedure as
//          the value of the Serializer parameter, and not obtained using the global
//          context property Serializatorxdto,
//      * MetadataObject - MetadataObject - after uploading the data, the handler was called.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportUserFavorites;
	NewHandler.BeforeUploadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

// Called when the registration of arbitrary handlers load the data.
//
// Parameters:
//  HandlersTable - ValueTable - In this procedure, it is required
//  to supplement this table of values with information about registered arbitrary
//  data loading handlers. Columns:
//    Data objectmetadata - Data objectmetadata - when loading data
//      , the registered handler should be called,
//    Handler - General module - a general module in which an arbitrary
//      data loading handler is implemented. A set of export procedures that should
//      to be implemented in the handler, depends on setting the values of the following
//      columns of the table of values,
//    Version - String - version number of the data upload/download handler interface
//      supported by the handler,
//    Before the links are set, a Boolean flag indicates whether the handler needs to be called before
//      matching the links (in the original IS and in the Cur) related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable procedure must be implemented before the links are supplied(),
//      which supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata -
//          the handler was called before matching the references of which,
//        Standard processing - Boolean - if the procedure is
//          set to False before providing links(), instead of the standard
//          link matching (searching for objects in the Cur IS with the same
//          natural key values that were unloaded from the IS source)
//          , the function Match Links() of the general module will be called in the procedure
//          Before the delivery of the links() whose value is the parameter Standardprocessing
//          it was set equal to False.
//          Parameters of the Match Links() function:
//            Container - Processing object.The
//              container manager used in the data upload process is the container manager. For more information, see the comment
//              to the program interface for processing the uploadingmediagercontainer,
//            the table of outgoing links - the table of assignments - containing information about links
//              unloaded from the source information system. Columns:
//                Source link - Any link is a link of the object of the original information security, which you want
//                  to match with the link in the Cur information security,
//                The remaining columns are equal to the fields of the object's natural key, which
//                  were passed to the function during the data upload process.
//                  Unloaded and unloaded data from the information database.It is required to provide a link to the Download()
//          The return value of the function Match Links() - Value tables, columns:
//            Source link - Any link is an object link unloaded from the source information system,
//            Link - Any link - a mapped source link in the Cur IS.
//        Failure - Boolean - If the value
//          of this parameter is set to True in the procedure before the provision of links(), the mapping of links corresponding
//          to the Cur metadata object will not be performed.
//    Before loading the type, the Boolean flag indicates whether the handler needs to be called before
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable Preload Type procedure() can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - before loading all the data of which
//          the handler was called,
//        Failure - Boolean - If the value of this
//          parameter is set to True in the Preload Type() procedure, all data objects corresponding to the Cur
//          metadata object will not be loaded.
//    Before loading the object - Boolean - flag of the need to call the handler before
//      loading the data object related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exported procedure for preloading an object() can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - Value constantmanagement, Directory object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          The register of the record setcountainment, the sequence of the record set, the recalculation of the record set -
//          the data object of the information database, before loading which the handler was called.
//          The value passed to the procedure before loading the object() as a parameter value
//          The object can be modified inside the handler procedure before loading the object().
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//        Failure - Boolean - if the value of this
//          parameter is set to True in the procedure for preloading the object(), the data object will not be loaded.
//    After loading the object - Boolean - flag of the need to call the handler after
//      loading the data object related to this
//      metadata object. If the value is set to True, the common handler module must
//      an exported procedure for post-loading an object() can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Object - constantmanagement values - Reference object, Document object,
//          Business ProcessObject, Taskobject, Plan Accountobject, Plan Exchange Object,
//          Type Characterization planobject, Type calculation planobject, recordsetreferences,
//          Register of Records Collection, Register of bookgalteryinabor records,
//          Register of recordscountainment, sequence of recordscountainment, Recalculation of recordscountainment -
//          the data object of the information database, after loading which the handler was called.
//        Artifacts - An array Of ObjectXDTO - additional data that is logically inextricably linked
//          to the data object, but is not part of it. Generated in exported procedures
//          Before loading the object() of the data upload handlers (see the procedure comment
//          When registering the processed data(). Each artifact must be an XDTO object,
//          for the type of which an abstract XDTO type is used as the base type
//          {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact. It is allowed to use XDTO packages,
//          in addition to those originally supplied as part of the Unloading and Unloading data subsystem.
//    After loading Type - Boolean - flag of the need to call the handler after
//      loading all data objects related to this
//      metadata object. If the value is set to True, the common handler module should
//      an exportable post-loading Type() procedure can be implemented
//      that supports the following parameters:
//        Container - Processing object.The
//          container manager used in the data upload process is the container manager. For more information, see the comment
//          on the program interface for processing the offload data of the Container manager.
//        Data objectmetadata - Data objectmetadata - after loading all the objects of which
//          the handler was called.
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportUserFavorites;
	NewHandler.BeforeDownloadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

#EndRegion

#EndRegion


#Region Private

#Region DataUploadAndDownloadHandlers


// Performed before uploading settings.
// 
// Parameters:
// 	Container - DataProcessorObject.ExportImportDataUserSettingsImportManager -
// 	Serializer - XDTOSerializer - 
// 	NameOfSettingsStore - String - 
// 	SettingsKey - String - see syntax -platform assistant.
// 	ObjectKey - String - see syntax -platform assistant.
// 	Settings - ValueStorage - 
// 	User - InfoBaseUser - 
// 	Presentation - String - 
// 	Artifacts - Array of XDTODataObject - additional data.
// 	Cancel - Boolean - indicates that processing was refused.
Procedure BeforeUploadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	If TypeOf(Settings) = Type("UserWorkFavorites") Then
		
		For Each FavoritesElement In Settings Do
			
			NewArtifact = XDTOFactory.Create(ArtifactTypeFavoritesItem());
			NewArtifact.Important = FavoritesElement.Important;
			NewArtifact.URL = MappingNavigationLinkToArtifact(FavoritesElement.URL);
			NewArtifact.Presentation = FavoritesElement.Presentation;
			
			Artifacts.Add(NewArtifact);
			
		EndDo;
		
		Settings = New UserWorkFavorites();
		
	EndIf;
	
EndProcedure

Procedure BeforeDownloadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	If TypeOf(Settings) = Type("UserWorkFavorites") Then
		
		For Each Artifact In Artifacts Do
			
			If Artifact.Type() = ArtifactTypeFavoritesItem() Then
				
				NewItem = New UserWorkFavoritesItem();
				NewItem.Important = Artifact.Important;
				NewItem.URL = NavigationLinkForMappingToArtifact(Artifact.URL);
				NewItem.Presentation = Artifact.Presentation;
				
				Settings.Add(NewItem);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

Function NavigationLinkForMappingToArtifact(Val Representation)
	
	Result = Representation.Template;
	
	If Representation.MainRef <> Undefined Then
		
		Var_Key = Representation.MainRef.Key;
		Ref = Representation.MainRef.Value;
		
		If Common.IsReference(TypeOf(Ref)) Then
		
			Result = StrReplace(Result, String(Var_Key) + ".Type", Ref.Metadata().FullName());
			Result = StrReplace(Result, String(Var_Key) + ".UUID",
				MappingUniqueIdentifierToNavigationLinkFormat(Ref.UUID()));
				
		EndIf;
		
	EndIf;
	
	For Each DisplayingAdditionalLink In Representation.AdditionalRef Do
		
		Var_Key = DisplayingAdditionalLink.Key;
		Ref = DisplayingAdditionalLink.Value;
		
		TypeRow = Common.TypePresentationString(TypeOf(Ref));
		Id_String = MappingUniqueIdentifierToNavigationLinkFormat(Ref.UUID());
		
		If DisplayingAdditionalLink.RequreTypeAnnotition Then
			
			SubstitutionString = TypeRow + ":" + Id_String;
			
		Else
			
			SubstitutionString = Id_String;
			
		EndIf;
		
		SubstitutionString = EncodeString(SubstitutionString, StringEncodingMethod.URLEncoding);
		
		Result = StrReplace(Result, String(Var_Key) + ".UUID", SubstitutionString);
		
	EndDo;
	
	RefStructure = NavigationLinkStructure_(Result);
	
	Result = RefStructure.Protocol + "/" + RefStructure.Type;
	
	If ValueIsFilled(RefStructure.Path) Then
		Result = Result + "/" + RefStructure.Path;
	EndIf;
	
	If ValueIsFilled(RefStructure.Parameters) Then
		Result = Result + "?" + RefStructure.Parameters;
	EndIf;
	
	Return Result;
	
EndFunction

Function MappingNavigationLinkToArtifact(Val URL)
	
	Representation = XDTOFactory.Create(TypeMappingNavigationLinkToArtifact());
	Representation.Template = URL;
	
	RefStructure = NavigationLinkStructure_(URL);
	
	If ThisIsNavigationLinkToInformationBaseObject(RefStructure) Then
		
		MetadataObject = MetadataObjectAlongPathInNavigationLink(RefStructure.Path);
		
		If MetadataObject <> Undefined Then
			
			If CommonCTL.IsRefData(MetadataObject) Then
				
				Var_Key = New UUID();
				
				Representation.MainRef = XDTOFactory.Create(TypeMappingLinkToArtifact());
				Representation.MainRef.Key = Var_Key;
				
				Representation.Template = StrReplace(Representation.Template, MetadataObject.FullName(), String(Var_Key) + ".Type");
				
			EndIf;
			
			LinksInParameters = LinksInNavigationLinkParameters(RefStructure.Parameters, MetadataObject);
			
			For Each String In LinksInParameters Do
				
				Representation.Template = StrReplace(Representation.Template, String.OriginalSubstring, String.DecodedSubstring);
				
				If String.ParameterName = "ref" Then
					
					Representation.MainRef.Value = XDTOSerializer.WriteXDTO(String.Ref);
					Representation.MainRef.RequreTypeAnnotition = String.RequiresTypeAnnotationInNavigationLink;
					Representation.Template = StrReplace(Representation.Template, String.SubstringLinks, String(Var_Key) + ".UUID");
					
				Else
					
					Var_Key = New UUID();
					
					DisplayingAdditionalLink = XDTOFactory.Create(TypeMappingLinkToArtifact());
					DisplayingAdditionalLink.Key = Var_Key;
					DisplayingAdditionalLink.Value = XDTOSerializer.WriteXDTO(String.Ref);
					DisplayingAdditionalLink.RequreTypeAnnotition = String.RequiresTypeAnnotationInNavigationLink;
					
					AdditionalLinks = Representation.AdditionalRef; // XDTOList
					AdditionalLinks.Add(DisplayingAdditionalLink);
					
					Representation.Template = StrReplace(Representation.Template, String.SubstringLinks, String(Var_Key) + ".UUID");
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Representation;
	
EndFunction

Function ThisIsNavigationLinkToInformationBaseObject(Val NavigationLinkStructure_)
	
	If NavigationLinkStructure_.Protocol = "e1cib"
		And NavigationLinkStructure_.Type = "data"
		And Not IsBlankString(NavigationLinkStructure_.Parameters) Then // Not localized
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function NavigationLinkStructure_(Val URL)
	
	Result = New Structure;
	Result.Insert("Protocol", "");
	Result.Insert("Type", "");
	Result.Insert("Path", "");
	Result.Insert("Parameters", "");
	
	SubstringsOfLink = StrSplit(URL, "/");
	
	If SubstringsOfLink.Count() >= 1 Then
		Result.Protocol = SubstringsOfLink[0];
	EndIf;
	
	If SubstringsOfLink.Count() >= 2 Then
		Result.Type = SubstringsOfLink[1];
	EndIf;
	
	If SubstringsOfLink.Count() >= 3 Then
		
		Body = SubstringsOfLink[2];
		
		SeparatorPosition = StrFind(Body, "?");
		
		If SeparatorPosition = 0 Then
			
			Result.Path = Body;
			Result.Parameters = "";
			
		Else
			
			Result.Path = Left(Body, SeparatorPosition - 1);
			Result.Parameters = StrReplace(Body, Result.Path + "?", "");
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function MetadataObjectAlongPathInNavigationLink(Val PathString)
	
	PathStructure = StrSplit(PathString, ".");
	
	If PathStructure.Count() >= 2 Then
		
		Return Metadata.FindByFullName(PathStructure[0] + "." + PathStructure[1]);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function LinksInNavigationLinkParameters(Val ParametersString1, Val MetadataObject)
	
	Result = New ValueTable();
	Result.Columns.Add("OriginalSubstring", New TypeDescription("String"));
	Result.Columns.Add("DecodedSubstring", New TypeDescription("String"));
	Result.Columns.Add("ParameterName", New TypeDescription("String"));
	Result.Columns.Add("Ref", CommonCTLCached.RefTypesDetails());
	Result.Columns.Add("SubstringLinks", New TypeDescription("String"));
	Result.Columns.Add("RequiresTypeAnnotationInNavigationLink", New TypeDescription("Boolean"));
	
	Substrings = StrSplit(ParametersString1, "&");
	
	For Each Substring In Substrings Do
		
		SeparatorPosition = StrFind(Substring, "=");
		
		FieldName = Left(Substring, SeparatorPosition - 1);
		Simple = StrReplace(Substring, FieldName + "=", "");
		
		If Not CommonCTL.IsEnum(MetadataObject)
			And CommonCTL.IsRefData(MetadataObject) 
			And FieldName = "ref" Then
			
			Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
			RefUUID = UniqueIDFromDisplayInNavigationLinkFormat(Simple);

			If RefUUID <> Undefined Then
			
				Ref = Manager.GetRef(RefUUID);
				
				ResultString1 = Result.Add();
				ResultString1.OriginalSubstring = Substring;
				ResultString1.DecodedSubstring = Substring;
				ResultString1.ParameterName = "ref";
				ResultString1.Ref = Ref;
				ResultString1.SubstringLinks = Simple;
				ResultString1.RequiresTypeAnnotationInNavigationLink = False;
				
			EndIf;

		ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
			
			OriginalFieldValue = Simple;
			Simple = DecodeString(Simple, StringEncodingMethod.URLEncoding);
			
			MeasurementField = MetadataObject.Dimensions.Find(FieldName);
			
			If MeasurementField = Undefined Then
				
				NumberOfPossibleTypes = 0;
				
			Else
				
				NumberOfPossibleTypes = NumberOfReferenceTypesInTypeDescription(MeasurementField.Type);
				
			EndIf;
			
			If NumberOfPossibleTypes = 1 Then
				
				RequiresTypeAnnotationInNavigationLink = False;
				Id_String = IdStringFromDisplayInNavigationLinkFormat(Simple);
				
				If Not StringFunctionsClientServer.IsUUID(Id_String) Then
					Continue;
				EndIf;
					
				EmptyRef = New(MeasurementField.Type.Types()[0]);
				
				If CommonCTL.IsEnum(EmptyRef.Metadata()) Then
					Continue;
				EndIf;
				
				Manager = Common.ObjectManagerByFullName(EmptyRef.Metadata().FullName());
				RefUUID = New UUID(Id_String);
				Ref = Manager.GetRef(RefUUID);
				
			ElsIf NumberOfPossibleTypes > 1 Then
				
				RequiresTypeAnnotationInNavigationLink = True;
				PositionOfTypeSeparator = StrFind(Simple, ":");
				
				If PositionOfTypeSeparator > 0 Then
					
					TypeName = Left(Simple, PositionOfTypeSeparator - 1);
					Id_String = IdStringFromDisplayInNavigationLinkFormat(
						StrReplace(Simple, TypeName + ":", ""));
					
					If Not StringFunctionsClientServer.IsUUID(Id_String) Then
						Continue;
					EndIf;
					
					EmptyRef = New(Type(TypeName));
					
					If CommonCTL.IsEnum(EmptyRef.Metadata()) Then
						Continue;
					EndIf;
				
					Manager = Common.ObjectManagerByFullName(EmptyRef.Metadata().FullName());
					RefUUID = New UUID(Id_String);
					Ref = Manager.GetRef(RefUUID);
					
				Else
					
					Continue;
					
				EndIf;
				
			Else
				
				Continue;
				
			EndIf;
			
			ResultString1 = Result.Add();
			ResultString1.OriginalSubstring = Substring;
			ResultString1.DecodedSubstring = StrReplace(Substring, OriginalFieldValue, Simple);
			ResultString1.ParameterName = FieldName;
			ResultString1.Ref = Ref;
			ResultString1.SubstringLinks = Simple;
			ResultString1.RequiresTypeAnnotationInNavigationLink = RequiresTypeAnnotationInNavigationLink;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function NumberOfReferenceTypesInTypeDescription(Val TypeDescription)
	
	Result = 0;
	
	For Each Type In TypeDescription.Types() Do
		
		If Not CommonCTL.IsPrimitiveType(Type) Then
			
			Result = Result + 1;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function MappingUniqueIdentifierToNavigationLinkFormat(Val Id)
	
	LinkID = String(Id);
	
	Return Mid(LinkID, 20, 4)
		+ Mid(LinkID, 25)
		+ Mid(LinkID, 15, 4)
		+ Mid(LinkID, 10, 4)
		+ Mid(LinkID, 1, 8);
	
EndFunction

Function UniqueIDFromDisplayInNavigationLinkFormat(Val Representation)
	
	Id_String = IdStringFromDisplayInNavigationLinkFormat(Representation);
	If StringFunctionsClientServer.IsUUID(Id_String) Then
		Return New UUID(Id_String);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function IdStringFromDisplayInNavigationLinkFormat(Val Representation)
	
	FirstPart    = Mid(Representation, 25, 8);
	SecondPart    = Mid(Representation, 21, 4);
	ThirdPart    = Mid(Representation, 17, 4);
	FourthPart = Mid(Representation, 1,  4);
	FifthPart     = Mid(Representation, 5,  12);
	
	Return FirstPart + "-" + SecondPart + "-" + ThirdPart + "-" + FourthPart + "-" + FifthPart;
	
EndFunction

Function ArtifactTypeFavoritesItem()
	
	Return XDTOFactory.Type(Package(), "FavoriteItemArtefact");
	
EndFunction

Function TypeMappingNavigationLinkToArtifact()
	
	Return XDTOFactory.Type(Package(), "URL");
	
EndFunction

Function TypeMappingLinkToArtifact()
	
	Return XDTOFactory.Type(Package(), "URLRef");
	
EndFunction

Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/UserWorkFavorites/1.0.0.1";
	
EndFunction

#EndRegion
