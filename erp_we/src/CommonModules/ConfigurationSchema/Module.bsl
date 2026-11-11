#Region Internal

// Binary schema data
// 
// Parameters: 
//  AnnotateReferenceTypes - Boolean
//  ConsiderDataExpansion - Boolean
// 
// Returns: 
//  BinaryData
Function SchemaBinaryData(AnnotateReferenceTypes = False, ConsiderDataExpansion = True) Export 	
	
	If Not ConsiderDataExpansion Then
		
		AddressInTempStorage = PutToTempStorage(Undefined);
		
		BackgroundJobParameters = New Array;
		BackgroundJobParameters.Add(AnnotateReferenceTypes);
		BackgroundJobParameters.Add(AddressInTempStorage);	
		
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(
			"ConfigurationSchema.PlaceBinarySchemaDataInTemporaryStorage", 
			BackgroundJobParameters);	
		BackgroundJob = BackgroundJob.WaitForExecutionCompletion();
		
		State = BackgroundJob.State;	
		If State = BackgroundJobState.Canceled Then
			Raise NStr("vi = 'Nhiệm vụ đã bị hủy';
						|ru = 'Задание отменено';
						|en = 'Job is canceled'; fa = 'Job is canceled';
						|it = 'Task annullato';
						|pl = 'Zadanie anulowano';
						|tr = 'Görev iptal edildi'");
		ElsIf State = BackgroundJobState.Failed Then
			Raise CloudTechnology.DetailedErrorText(BackgroundJob.ErrorInfo);
		EndIf;
			
		BinarySchemaDataOfCurConfiguration = GetFromTempStorage(AddressInTempStorage);
		DeleteFromTempStorage(AddressInTempStorage);
		
		If BinarySchemaDataOfCurConfiguration = Undefined Then
			Raise NStr("vi = 'Không thể nhận dữ liệu nhị phân của sơ đồ cấu hình';
						|ru = 'Не удалось получить двоичные данные схемы конфигурации';
						|en = 'Cannot receive the binary configuration schema data'; fa = 'Cannot receive the binary configuration schema data';
						|it = 'Non è stato possibile ricevere i dati binari dello schema di configurazione';
						|pl = 'Nie udało się otrzymać danych binarnych schematu konfiguracji';
						|tr = 'Konfigürasyon şemasının ikili verileri alınamadı'");
		EndIf;
		
		Return BinarySchemaDataOfCurConfiguration;
		
	EndIf;
		
	SetOfSchemes = XDTOFactory.ExportXMLSchema(UriNamespacesConfigurationScheme());
	Schema = SetOfSchemes[0];
	Schema.UpdateDOMElement();
	
	If AnnotateReferenceTypes Then
		
		TypesRequiringAnnotationOfReferences = ExportImportDataInternalEvents.GetTypesThatRequireAnnotationOfLinksWhenUnloading();

		If ValueIsFilled(TypesRequiringAnnotationOfReferences) Then

			SpecifiedTypes = New Map;
			
			For Each Type In TypesRequiringAnnotationOfReferences Do
				SpecifiedTypes.Insert(ExportImportDataInternal.XMLRefType(Type), True);
			EndDo;

			Namespace = New Map;
			Namespace.Insert("xs", "http://www.w3.org/2001/XMLSchema");
			DOMNamespaceResolver = New DOMNamespaceResolver(Namespace);
			XPathText = "/xs:schema/xs:complexType/xs:sequence/xs:element[starts-with(@type,'tns:')]";

			Query = Schema.DOMDocument.CreateXPathExpression(XPathText, DOMNamespaceResolver);
			Result = Query.Evaluate(Schema.DOMDocument);

			While True Do

				FieldNode_ = Result.IterateNext();
				If FieldNode_ = Undefined Then
					Break;
				EndIf;
				AttributeType = FieldNode_.Attributes.GetNamedItem("type");
				TypeWithoutNSPrefix = Mid(AttributeType.TextContent, StrLen("tns:") + 1);

				If SpecifiedTypes.Get(TypeWithoutNSPrefix) = Undefined Then
					Continue;
				EndIf;

				FieldNode_.SetAttribute("nillable", "true");
				FieldNode_.RemoveAttribute("type");
			EndDo;
			
		EndIf;
	EndIf;
	
	WriteStream = New MemoryStream();
	
	XMLWriter = New XMLWriter();	
	XMLWriter.OpenStream(WriteStream);
	
	DOMWriter = New DOMWriter;
	DOMWriter.Write(Schema.DOMDocument, XMLWriter);
	
	XMLWriter.Close();
	
	Return WriteStream.CloseAndGetBinaryData();

EndFunction

#EndRegion

#Region Private

Function UriNamespacesConfigurationScheme()
	Return "http://v8.1c.ru/8.1/data/enterprise/current-config";   
EndFunction

Procedure PlaceBinarySchemaDataInTemporaryStorage(AnnotateReferenceTypes, SchemaURL) Export
	PutToTempStorage(
		SchemaBinaryData(AnnotateReferenceTypes),
		SchemaURL);
EndProcedure

#EndRegion
