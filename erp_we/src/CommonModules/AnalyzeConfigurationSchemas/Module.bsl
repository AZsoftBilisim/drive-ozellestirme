#Region Internal

Function DescriptionsOfDifferencesInConfigurationSchemes(SourceConfigurationSchemaData, DestinationConfigurationSchemaData) Export

	UriNamespacesConfigurationScheme = UriNamespacesConfigurationScheme();

	SourceConfigurationSchema = XMLSchema(SourceConfigurationSchemaData);
	SourceConfigurationFactory = FactoryByScheme(SourceConfigurationSchema);
	SourceConfigurationPackage = FactoryPackage(SourceConfigurationFactory, UriNamespacesConfigurationScheme);

	DestinationConfigurationSchema = XMLSchema(DestinationConfigurationSchemaData);
	DestinationConfigurationFactory = FactoryByScheme(DestinationConfigurationSchema);
	DestinationConfigurationFactoryPackage = FactoryPackage(DestinationConfigurationFactory, UriNamespacesConfigurationScheme);

	AllObjectTypeNames = New Array;
	CommonClientServer.SupplementArray(AllObjectTypeNames,
		NamesOfPackageObjectTypes(SourceConfigurationPackage));
	CommonClientServer.SupplementArray(AllObjectTypeNames,
		NamesOfPackageObjectTypes(DestinationConfigurationFactoryPackage),
		True);

	DescriptionsOfDifferences = New Array;

	NamesOfBaseTypesOfComparedTypesOfXDTO = NamesOfBaseTypesOfComparedTypesOfXDTO();
	StandardRequisitesOfBasicTypesOfXDTO = StandardRequisitesOfBasicTypesOfXDTO();
	StructureOfSearchForStandardDetails = New Structure("PropertyName, BaseTypeName");
	TypeNamesOfOwnersOfBasicTypesOfTableParts = TypeNamesOfOwnersOfBasicTypesOfTableParts();

	For Each ObjectTypeName In AllObjectTypeNames Do

		InformationAboutTypeOfObject = InformationAboutTypeOfObject(ObjectTypeName);

		If InformationAboutTypeOfObject = Undefined Then
			Continue;
		EndIf;

		BaseTypeName = NamesOfBaseTypesOfComparedTypesOfXDTO.Get(InformationAboutTypeOfObject.TypeNameXDTO);

		If BaseTypeName = Undefined Then
			Continue;
		EndIf;

		If BaseTypeName = BaseTypeNameEnumeration() Then
	
			FullMetadataObjectName = StrTemplate("%1.%2",
				BaseTypeName,
				InformationAboutTypeOfObject.NameOfApplicationType);

			DestinationConfigurationObjectType = DestinationConfigurationFactory.Type(UriNamespacesConfigurationScheme, ObjectTypeName);

			If DestinationConfigurationObjectType = Undefined Then
				
				DescriptionsOfDifferences.Add(StrTemplate(MetadataObjectTemplateMissingInDestination(),
					FullMetadataObjectName));
				Continue;
				
			EndIf;

			SourceConfigurationObjectType = SourceConfigurationFactory.Type(UriNamespacesConfigurationScheme, ObjectTypeName);

			If SourceConfigurationObjectType = Undefined Then
				
				Continue;
				
			EndIf;

			ExportConfigurationObjectValuesNames = ObjectValuesNames(SourceConfigurationObjectType);
			ServiceConfigurationObjectValuesNames = ObjectValuesNames(DestinationConfigurationObjectType);

			For Each ExportConfigurationObjectValueName In ExportConfigurationObjectValuesNames Do

				PropertyOfServiceConfigurationObject = ServiceConfigurationObjectValuesNames.Find(ExportConfigurationObjectValueName);

				If PropertyOfServiceConfigurationObject = Undefined Then

					DescriptionsOfDifferences.Add(StrTemplate(ValueTemplateMissingInDestination(),
						ExportConfigurationObjectValueName,
						FullMetadataObjectName));

				EndIf;

			EndDo;

		Else

			TypeNameOfOwnerOfTablePart = TypeNamesOfOwnersOfBasicTypesOfTableParts.Get(BaseTypeName);
			IsTabularSection = TypeNameOfOwnerOfTablePart <> Undefined;

			If IsTabularSection Then

				PartsOfApplicationTypeName = StrSplit(InformationAboutTypeOfObject.NameOfApplicationType, ".");
				InUpperPartOfApplicationTypeName = PartsOfApplicationTypeName.UBound();
				PartsOfFullNameOfMetadataObject = New Array;
				PartsOfFullNameOfMetadataObject.Add(TypeNameOfOwnerOfTablePart);

				For IndexOf = 0 To InUpperPartOfApplicationTypeName - 1 Do

					PartsOfFullNameOfMetadataObject.Add(PartsOfApplicationTypeName[IndexOf]);

				EndDo;

				FullMetadataObjectName = StrConcat(PartsOfFullNameOfMetadataObject, ".");
				TabularSectionName = PartsOfApplicationTypeName[InUpperPartOfApplicationTypeName];

			Else

				FullMetadataObjectName = StrTemplate("%1.%2",
					BaseTypeName,
					InformationAboutTypeOfObject.NameOfApplicationType);
				TabularSectionName = Undefined;

			EndIf;

			DestinationConfigurationObjectType = DestinationConfigurationFactory.Type(UriNamespacesConfigurationScheme, ObjectTypeName);

			If DestinationConfigurationObjectType = Undefined Then

				If Not IsTabularSection Then

					DescriptionsOfDifferences.Add(StrTemplate(MetadataObjectTemplateMissingInDestination(),
						FullMetadataObjectName));

				EndIf;

				Continue;

			EndIf;

			SourceConfigurationObjectType = SourceConfigurationFactory.Type(UriNamespacesConfigurationScheme, ObjectTypeName);

			If SourceConfigurationObjectType = Undefined Then

				If Not IsTabularSection Then

					DescriptionsOfDifferences.Add(StrTemplate(MetadataObjectTemplateMissingInSource(),
						FullMetadataObjectName));

				EndIf;

				Continue;

			EndIf;

			AllNamesOfObjectTypeProperties = New Array;
			CommonClientServer.SupplementArray(AllNamesOfObjectTypeProperties, 
				NamesOfObjectTypeProperties(SourceConfigurationObjectType)); 
			CommonClientServer.SupplementArray(AllNamesOfObjectTypeProperties, 
				NamesOfObjectTypeProperties(DestinationConfigurationObjectType),
				True);

			SourceConfigurationObjectTypeProperties = SourceConfigurationObjectType.Properties;
			DestinationConfigurationObjectTypeProperties = DestinationConfigurationObjectType.Properties;

			StructureOfSearchForStandardDetails.BaseTypeName = BaseTypeName;

			For Each NameOfObjectTypeProperty In AllNamesOfObjectTypeProperties Do

				StructureOfSearchForStandardDetails.PropertyName = NameOfObjectTypeProperty;
				LinesOfStandardDetails = StandardRequisitesOfBasicTypesOfXDTO.FindRows(StructureOfSearchForStandardDetails);

				If ValueIsFilled(LinesOfStandardDetails) Then

					AttributeName = LinesOfStandardDetails[0].StandardAttributeName;

				Else

					AttributeName = NameOfObjectTypeProperty;

				EndIf;

				PropertyOfUploadConfigurationObject = SourceConfigurationObjectTypeProperties.Get(NameOfObjectTypeProperty);
				PropertyOfServiceConfigurationObject = DestinationConfigurationObjectTypeProperties.Get(NameOfObjectTypeProperty);

				If PropertyOfServiceConfigurationObject = Undefined Then

					If ThisIsXDTOTypeOfTabularPart(PropertyOfUploadConfigurationObject.Type.Name, NamesOfBaseTypesOfComparedTypesOfXDTO, TypeNamesOfOwnersOfBasicTypesOfTableParts) Then

						DifferenceDescriptionTemplate = TabularPartTemplateMissingInDestination();

					Else

						DifferenceDescriptionTemplate = AttributeTemplateMissingInDestination();

					EndIf;

					DescriptionsOfDifferences.Add(StrTemplate(DifferenceDescriptionTemplate,
						AttributeName,
						FullMetadataObjectName));
					Continue;

				EndIf;

				If PropertyOfUploadConfigurationObject = Undefined Then

					If ThisIsXDTOTypeOfTabularPart(PropertyOfServiceConfigurationObject.Type.Name, NamesOfBaseTypesOfComparedTypesOfXDTO, TypeNamesOfOwnersOfBasicTypesOfTableParts) Then

						DifferenceDescriptionTemplate = TabularPartTemplateMissingInSource();

					Else

						DifferenceDescriptionTemplate = AttributeTemplateMissingInSource();

					EndIf;

					DescriptionsOfDifferences.Add(StrTemplate(DifferenceDescriptionTemplate,
						AttributeName,
						FullMetadataObjectName));
					Continue;

				EndIf;

				If PropertyOfUploadConfigurationObject.Type.Name <> PropertyOfServiceConfigurationObject.Type.Name Then

					If IsTabularSection Then

						DescriptionOfDifference = StrTemplate(DifferentTablePartAttributeTypeTemplate(),
							AttributeName,
							TabularSectionName,
							FullMetadataObjectName);

					Else

						DescriptionOfDifference = StrTemplate(DifferentAttributeTemplateType(),
							AttributeName,
							FullMetadataObjectName);

					EndIf;

					DescriptionsOfDifferences.Add(DescriptionOfDifference);

				EndIf;

			EndDo;

		EndIf;

	EndDo;

	Return DescriptionsOfDifferences;

EndFunction

#EndRegion

#Region Private

#Region StandardAttributes

Function StandardRequisitesOfBasicTypesOfXDTO()

	StandardDetailsOfBasicTypes = New ValueTable;
	StandardDetailsOfBasicTypes.Columns.Add("PropertyName");
	StandardDetailsOfBasicTypes.Columns.Add("BaseTypeName");
	StandardDetailsOfBasicTypes.Columns.Add("StandardAttributeName");

	AddExchangePlansStandardAttributes(StandardDetailsOfBasicTypes);
	AddStandardDetailsOfConstants(StandardDetailsOfBasicTypes);
	AddStandardReferenceBookDetails(StandardDetailsOfBasicTypes);
	AddStandardDetailsOfDocuments(StandardDetailsOfBasicTypes);
	AddStandardSequenceDetails(StandardDetailsOfBasicTypes);
	SupplementWithStandardDetailsOfPlansOfTypesOfCharacteristics(StandardDetailsOfBasicTypes);
	AddStandardDetailsOfAccountPlans(StandardDetailsOfBasicTypes);
	ToSupplementWithStandardDetailsOfPlansOfTypesOfCalculation(StandardDetailsOfBasicTypes);
	SupplementWithStandardDetailsOfInformationRegisters(StandardDetailsOfBasicTypes);
	SupplementWithStandardDetailsOfAccumulationRegisters(StandardDetailsOfBasicTypes);
	SupplementWithStandardDetailsOfAccountingRegisters(StandardDetailsOfBasicTypes);
	AddStandardDetailsOfCalculationRegisters(StandardDetailsOfBasicTypes);
	AddStandardBusinessProcessDetails(StandardDetailsOfBasicTypes);
	AddStandardTaskDetails(StandardDetailsOfBasicTypes);
	
	Return StandardDetailsOfBasicTypes;
	
EndFunction

Procedure AddExchangePlansStandardAttributes(StandardDetailsOfBasicTypes)

	ExchangePlanBaseTypeName = ExchangePlanBaseTypeName();
	StandardAttributeNameRef = StandardAttributeNameRef();

	SupplementTableOfStandardDetails(
		"Ref",
		ExchangePlanBaseTypeName,
		StandardAttributeNameRef,
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		ExchangePlanBaseTypeName,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Code",
		ExchangePlanBaseTypeName,
		StandardAttributeNameCode(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Description",
		ExchangePlanBaseTypeName,
		StandardAttributeNameDescription(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"SentNo",
		ExchangePlanBaseTypeName,
		StandardAttributeNameSentNo(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ReceivedNo",
		ExchangePlanBaseTypeName,
		StandardAttributeNameReceivedNo(),
		StandardDetailsOfBasicTypes);

		SupplementTableOfStandardDetails(
		"ThisNode",
		ExchangePlanBaseTypeName,
		StandardAttributeNameThisNode(),
		StandardDetailsOfBasicTypes);

	ExchangePlanBaseTypeNameTabularPart = ExchangePlanBaseTypeNameTabularPart();

	SupplementTableOfStandardDetails(
		"Ref",
		ExchangePlanBaseTypeNameTabularPart,
		StandardAttributeNameRef,
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardDetailsOfConstants(StandardDetailsOfBasicTypes)

	NameOfBaseTypeConstant = NameOfBaseTypeConstant();

	SupplementTableOfStandardDetails(
		"Type",
		NameOfBaseTypeConstant,
		StandardAttributeNameType(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Value",
		NameOfBaseTypeConstant,
		StandardAttributeNameValue(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardReferenceBookDetails(StandardDetailsOfBasicTypes)

	NameOfBaseTypeReference = NameOfBaseTypeReference();
	StandardAttributeNameRef = StandardAttributeNameRef();

	SupplementTableOfStandardDetails(
		"IsFolder",
		NameOfBaseTypeReference,
		StandardAttributeNameIsFolder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeReference,
		StandardAttributeNameRef,
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBaseTypeReference,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Parent",
		NameOfBaseTypeReference,
		StandardAttributeNameParent(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Owner",
		NameOfBaseTypeReference,
		StandardAttributeNameOwner(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Code",
		NameOfBaseTypeReference,
		StandardAttributeNameCode(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Description",
		NameOfBaseTypeReference,
		StandardAttributeNameDescription(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"PredefinedDataName",
		NameOfBaseTypeReference,
		StandardAttributeNamePredefinedDataName(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeReferenceTablePart(),
		StandardAttributeNameRef,
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardDetailsOfDocuments(StandardDetailsOfBasicTypes)

	StandardAttributeNameRef = StandardAttributeNameRef();
	NameOfBaseTypeDocument = NameOfBaseTypeDocument();

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeDocument,
		StandardAttributeNameRef,
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Number",
		NameOfBaseTypeDocument,
		StandardAttributeNameNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Date",
		NameOfBaseTypeDocument,
		StandardAttributeNameDate(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Posted",
		NameOfBaseTypeDocument,
		StandardAttributeNamePosted(),
		StandardDetailsOfBasicTypes);	

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBaseTypeDocument,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);	

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeDocumentTabularPart(),
		StandardAttributeNameRef,
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardSequenceDetails(StandardDetailsOfBasicTypes)

	NameOfBaseTypeSequence = NameOfBaseTypeSequence();

	SupplementTableOfStandardDetails(
		"Recorder",
		NameOfBaseTypeSequence,
		StandardAttributeNameRecorder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Period",
		NameOfBaseTypeSequence,
		StandardAttributeNamePeriod(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure SupplementWithStandardDetailsOfPlansOfTypesOfCharacteristics(StandardDetailsOfBasicTypes)

	NameOfBaseTypePlanOfTypesOfCharacteristics = NameOfBaseTypePlanOfTypesOfCharacteristics(); 

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Code",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameCode(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Description",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameDescription(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ValueType",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameValueType(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Parent",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameParent(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"IsFolder",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameIsFolder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"PredefinedDataName",
		NameOfBaseTypePlanOfTypesOfCharacteristics,
		StandardAttributeNamePredefinedDataName(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypePlanOfTypesOfCharacteristicsTabularPart(),
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardDetailsOfAccountPlans(StandardDetailsOfBasicTypes)

	NameOfBaseTypeChartOfAccounts = NameOfBaseTypeChartOfAccounts(); 

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Code",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameCode(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Description",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameDescription(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Order",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameOrder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Parent",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameParent(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Type",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameKind(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"OffBalance",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameOffBalance(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"PredefinedDataName",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNamePredefinedDataName(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ExtDimensionType",
		NameOfBaseTypeChartOfAccounts,
		StandardAttributeNameExtDimensionType(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeChartOfAccountsTabularPart(),
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure ToSupplementWithStandardDetailsOfPlansOfTypesOfCalculation(StandardDetailsOfBasicTypes)

	NameOfBaseTypeCalculationTypesPlan = NameOfBaseTypeCalculationTypesPlan();

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Code",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameCode(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Description",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameDescription(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);	

	SupplementTableOfStandardDetails(
		"PredefinedDataName",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNamePredefinedDataName(),
		StandardDetailsOfBasicTypes);	

	SupplementTableOfStandardDetails(
		"DisplacingCalculationTypes",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameDisplacingCalculationTypes(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"LeadingCalculationTypes",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameLeadingCalculationTypes(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"BaseCalculationTypes",
		NameOfBaseTypeCalculationTypesPlan,
		StandardAttributeNameBaseCalculationTypes(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypePlanOfCalculationTypesTabularPart(),
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure SupplementWithStandardDetailsOfInformationRegisters(StandardDetailsOfBasicTypes)

	NameOfBaseTypeInformationRegister = NameOfBaseTypeInformationRegister();

	SupplementTableOfStandardDetails(
		"Period",
		NameOfBaseTypeInformationRegister,
		StandardAttributeNamePeriod(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Recorder",
		NameOfBaseTypeInformationRegister,
		StandardAttributeNameRecorder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"LineNumber",
		NameOfBaseTypeInformationRegister,
		StandardAttributeNameLineNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Active",
		NameOfBaseTypeInformationRegister,
		StandardAttributeNameActive(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure SupplementWithStandardDetailsOfAccumulationRegisters(StandardDetailsOfBasicTypes)

	NameOfBaseTypeAccumulationRegister = NameOfBaseTypeAccumulationRegister();

	SupplementTableOfStandardDetails(
		"Period",
		NameOfBaseTypeAccumulationRegister,
		StandardAttributeNamePeriod(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Recorder",
		NameOfBaseTypeAccumulationRegister,
		StandardAttributeNameRecorder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"LineNumber",
		NameOfBaseTypeAccumulationRegister,
		StandardAttributeNameLineNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Active",
		NameOfBaseTypeAccumulationRegister,
		StandardAttributeNameActive(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"RecordType",
		NameOfBaseTypeAccumulationRegister,
		StandardAttributeNameRecordType(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure SupplementWithStandardDetailsOfAccountingRegisters(StandardDetailsOfBasicTypes)

	NameOfBaseTypeAccountingRegister = NameOfBaseTypeAccountingRegister();

	SupplementTableOfStandardDetails(
		"Period",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNamePeriod(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Recorder",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameRecorder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"LineNumber",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameLineNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Active",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameActive(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Account",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameAccount(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"AccountCr",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameAccountCr(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ExtDimensionsCr",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameExtDimensionsCr(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"AccountDr",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameAccountDr(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ExtDimensionsDr",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameExtDimensionsDr(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"RecordType",
		NameOfBaseTypeAccountingRegister,
		StandardAttributeNameRecordType(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardDetailsOfCalculationRegisters(StandardDetailsOfBasicTypes)

	NameOfBaseTypeCalculationRegister = NameOfBaseTypeCalculationRegister();

	SupplementTableOfStandardDetails(
		"RegistrationPeriod",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameRegistrationPeriod(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Recorder",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameRecorder(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"LineNumber",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameLineNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"CalculationType",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameCalculationType(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ActionPeriod",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameActionPeriod(),
		StandardDetailsOfBasicTypes);	

	SupplementTableOfStandardDetails(
		"Active",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameActive(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"ReversingEntry",
		NameOfBaseTypeCalculationRegister,
		StandardAttributeNameReversingEntry(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardBusinessProcessDetails(StandardDetailsOfBasicTypes)

	NameOfBusinessProcessBaseType = NameOfBusinessProcessBaseType();

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Number",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Date",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameDate(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"HeadTask",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameHeadTask(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Started",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameStarted(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Completed",
		NameOfBusinessProcessBaseType,
		StandardAttributeNameCompleted(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure AddStandardTaskDetails(StandardDetailsOfBasicTypes)

	NameOfBaseTypeTask = NameOfBaseTypeTask(); 

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeTask,
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Number",
		NameOfBaseTypeTask,
		StandardAttributeNameNumber(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Description",
		NameOfBaseTypeTask,
		StandardAttributeNameDescription(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Date",
		NameOfBaseTypeTask,
		StandardAttributeNameDate(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"DeletionMark",
		NameOfBaseTypeTask,
		StandardAttributeNameDeletionMark(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"BusinessProcess",
		NameOfBaseTypeTask,
		StandardAttributeNameBusinessProcess(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"RoutePoint",
		NameOfBaseTypeTask,
		StandardAttributeNameRoutePoint(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Executed",
		NameOfBaseTypeTask,
		StandardAttributeNameExecuted(),
		StandardDetailsOfBasicTypes);

	SupplementTableOfStandardDetails(
		"Ref",
		NameOfBaseTypeTaskTabularPart(),
		StandardAttributeNameRef(),
		StandardDetailsOfBasicTypes);

EndProcedure

Procedure SupplementTableOfStandardDetails(PropertyName, BaseTypeName, StandardAttributeName, TableOfStandardDetails)

	NewRow = TableOfStandardDetails.Add();
	NewRow.PropertyName = PropertyName;
	NewRow.BaseTypeName = BaseTypeName;
	NewRow.StandardAttributeName = StandardAttributeName;

EndProcedure

Function StandardAttributeNameRecorder()

	Return "Recorder";

EndFunction

Function StandardAttributeNameActive()

	Return "Active";

EndFunction

Function StandardAttributeNamePeriod()

	Return "Period";

EndFunction

Function StandardAttributeNameRecordType()

	Return "RecordType";

EndFunction

Function StandardAttributeNameIsFolder()

	Return "IsFolder";

EndFunction

Function StandardAttributeNameCode()

	Return "Code";

EndFunction

Function StandardAttributeNameDeletionMark()

	Return "DeletionMark";

EndFunction

Function StandardAttributeNameDescription()

	Return "Description";

EndFunction

Function StandardAttributeNameParent()

	Return "Parent";

EndFunction

Function StandardAttributeNameRef()

	Return "Ref";

EndFunction

Function StandardAttributeNameDate()

	Return "Date";

EndFunction

Function StandardAttributeNameOrder()

	Return "Order";

EndFunction

Function StandardAttributeNamePredefinedDataName()

	Return "PredefinedDataName";

EndFunction

Function StandardAttributeNameType()

	Return "Type";

EndFunction

Function StandardAttributeNameLineNumber()

	Return "LineNumber";

EndFunction

Function StandardAttributeNameKind()

	Return "Kind";

EndFunction

Function StandardAttributeNameNumber()

	Return "Number";

EndFunction

Function StandardAttributeNameSentNo()

	Return "SentNo";

EndFunction

Function StandardAttributeNameReceivedNo()

	Return "ReceivedNo";

EndFunction

Function StandardAttributeNameThisNode()

	Return "ThisNode";

EndFunction

Function StandardAttributeNameValue()

	Return "Value";

EndFunction

Function StandardAttributeNameOwner()

	Return "Owner";

EndFunction

Function StandardAttributeNamePosted()

	Return "Posted";

EndFunction

Function StandardAttributeNameValueType()

	Return "ValueType";

EndFunction

Function StandardAttributeNameOffBalance()

	Return "OffBalance";

EndFunction

Function StandardAttributeNameExtDimensionType()

	Return "ExtDimensionType";

EndFunction

Function StandardAttributeNameDisplacingCalculationTypes()

	Return "DisplacingCalculationTypes";

EndFunction

Function StandardAttributeNameLeadingCalculationTypes()

	Return "LeadingCalculationTypes";

EndFunction

Function StandardAttributeNameBaseCalculationTypes()

	Return "BaseCalculationTypes";

EndFunction

Function StandardAttributeNameAccount()

	Return "Account";

EndFunction

Function StandardAttributeNameAccountCr()

	Return "AccountCr";

EndFunction

Function StandardAttributeNameExtDimensionsCr()

	Return "ExtDimensionCr";

EndFunction

Function StandardAttributeNameAccountDr()

	Return "AccountDr";

EndFunction

Function StandardAttributeNameExtDimensionsDr()

	Return "ExtDimensionDr";

EndFunction

Function StandardAttributeNameRegistrationPeriod()

	Return "RegistrationPeriod";

EndFunction

Function StandardAttributeNameCalculationType()

	Return "CalculationType";

EndFunction

Function StandardAttributeNameActionPeriod()

	Return "ActionPeriod";

EndFunction

Function StandardAttributeNameReversingEntry()

	Return "ReversingEntry";

EndFunction

Function StandardAttributeNameHeadTask()

	Return "HeadTask";

EndFunction

Function StandardAttributeNameStarted()

	Return "Started";

EndFunction

Function StandardAttributeNameCompleted()

	Return "Completed";

EndFunction

Function StandardAttributeNameBusinessProcess()

	Return "BusinessProcess";

EndFunction

Function StandardAttributeNameRoutePoint()

	Return "RoutePoint";

EndFunction

Function StandardAttributeNameExecuted()

	Return "Executed";

EndFunction

#EndRegion

#Region BasicTypes

Function ThisIsBasicTypeOfTablePart(BaseTypeName, TypeNamesOfOwnersOfBasicTypesOfTableParts)

	Return TypeNamesOfOwnersOfBasicTypesOfTableParts.Get(BaseTypeName) <> Undefined;

EndFunction

Function ExchangePlanBaseTypeName()

	Return "ExchangePlan";

EndFunction

Function ExchangePlanBaseTypeNameTabularPart()

	Return "ExchangePlanTabularSection";

EndFunction

Function NameOfBaseTypeConstant()

	Return "Constant";

EndFunction

Function NameOfBaseTypeReference()

	Return "Catalog";

EndFunction

Function NameOfBaseTypeReferenceTablePart()

	Return "CatalogTabularSection";

EndFunction

Function NameOfBaseTypeDocument()

	Return "Document";

EndFunction

Function NameOfBaseTypeDocumentTabularPart()

	Return "DocumentTabularSection";

EndFunction

Function NameOfBaseTypeSequence()

	Return "Sequence";

EndFunction

Function BaseTypeNameEnumeration()

	Return "Enum";

EndFunction

Function NameOfBaseTypePlanOfTypesOfCharacteristics()

	Return "ChartOfCharacteristicTypes";

EndFunction

Function NameOfBaseTypePlanOfTypesOfCharacteristicsTabularPart()

	Return "ChartOfCharacteristicTypesTabularSection";

EndFunction

Function NameOfBaseTypeChartOfAccounts()

	Return "ChartOfAccounts";

EndFunction

Function NameOfBaseTypeChartOfAccountsTabularPart()

	Return "ChartOfAccountsTabularSection";

EndFunction

Function NameOfBaseTypeCalculationTypesPlan()

	Return "ChartOfCalculationTypes";

EndFunction

Function NameOfBaseTypePlanOfCalculationTypesTabularPart()

	Return "ChartOfCalculationTypesTabularSection";

EndFunction

Function NameOfBaseTypeInformationRegister()

	Return "InformationRegister";

EndFunction

Function NameOfBaseTypeAccumulationRegister()

	Return "AccumulationRegister";

EndFunction

Function NameOfBaseTypeAccountingRegister()

	Return "AccountingRegister";

EndFunction

Function NameOfBaseTypeCalculationRegister()

	Return "CalculationRegister";

EndFunction

Function NameOfBusinessProcessBaseType()

	Return "BusinessProcess";

EndFunction

Function NameOfBaseTypeBusinessProcessTabularPart()

	Return "BusinessProcessTabularSection";

EndFunction

Function NameOfBaseTypeTask()

	Return "Task";

EndFunction

Function NameOfBaseTypeTaskTabularPart()

	Return "TaskTabularSection";

EndFunction

Function TypeNamesOfOwnersOfBasicTypesOfTableParts()

	TypeNamesOfOwnersOfBasicTypesOfTableParts = New Map;

	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		ExchangePlanBaseTypeNameTabularPart(),
		ExchangePlanBaseTypeName());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypeReferenceTablePart(),
		NameOfBaseTypeReference());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypeDocumentTabularPart(),
		NameOfBaseTypeDocument());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypePlanOfTypesOfCharacteristicsTabularPart(),
		NameOfBaseTypePlanOfTypesOfCharacteristics());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypeChartOfAccountsTabularPart(),
		NameOfBaseTypeChartOfAccounts());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypePlanOfCalculationTypesTabularPart(),
		NameOfBaseTypeCalculationTypesPlan());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypeBusinessProcessTabularPart(),
		NameOfBusinessProcessBaseType());
	TypeNamesOfOwnersOfBasicTypesOfTableParts.Insert(
		NameOfBaseTypeTaskTabularPart(),
		NameOfBaseTypeTask());

	Return TypeNamesOfOwnersOfBasicTypesOfTableParts;

EndFunction

#EndRegion

Function NamesOfObjectTypeProperties(ObjectType)

	NamesOfObjectTypeProperties = New Array;

	For Each Property In ObjectType.Properties Do

		NamesOfObjectTypeProperties.Add(Property.Name);

	EndDo;

	Return NamesOfObjectTypeProperties;

EndFunction

Function ObjectValuesNames(ObjectType)

	ObjectValuesNames = New Array;

	For Each Enum In ObjectType.Facets.Enumerations Do

		ObjectValuesNames.Add(Enum.Value);

	EndDo;

	Return ObjectValuesNames;

EndFunction

Function NamesOfPackageObjectTypes(Package) 

	NamesOfPackageObjectTypes = New Array;
	TypeObjectTypeXDTO = Type("XDTOObjectType");
	TypeXDTOValueType = Type("XDTOValueType");

	For Each Type In Package Do

		If TypeOf(Type) = TypeObjectTypeXDTO
			Or TypeOf(Type) = TypeXDTOValueType Then

			NamesOfPackageObjectTypes.Add(Type.Name);

		EndIf;

	EndDo;

	Return NamesOfPackageObjectTypes;

EndFunction

Function XMLSchema(SchemaBinaryData)

	ReadStream = SchemaBinaryData.OpenStreamForRead();

	Read = New XMLReader;
	Read.OpenStream(ReadStream);

	Builder = New DOMBuilder;
	Document = Builder.Read(Read);

	ReadStream.Close();

	CircuitBuilder = New XMLSchemaBuilder;	

	Return CircuitBuilder.CreateXMLSchema(Document);

EndFunction

Function FactoryByScheme(Schema)

	SetOfSchemes = New XMLSchemaSet;
	SetOfSchemes.Add(Schema);

	Return New XDTOFactory(SetOfSchemes);

EndFunction

Function FactoryPackage(Factory, NamespaceURI)

	Return Factory.Packages.Get(NamespaceURI);

EndFunction

Function UriNamespacesConfigurationScheme()

	Return "http://v8.1c.ru/8.1/data/enterprise/current-config";

EndFunction

Function ThisIsXDTOTypeOfTabularPart(TypeNameXDTO, NamesOfBaseTypesOfComparedTypesOfXDTO, TypeNamesOfOwnersOfBasicTypesOfTableParts)

	ThisIsXDTOTypeOfTabularPart = False;
	InformationAboutTypeOfObject = InformationAboutTypeOfObject(TypeNameXDTO);

	If InformationAboutTypeOfObject <> Undefined Then

		BaseTypeName = NamesOfBaseTypesOfComparedTypesOfXDTO.Get(InformationAboutTypeOfObject.TypeNameXDTO);

		If BaseTypeName <> Undefined Then

			ThisIsXDTOTypeOfTabularPart = ThisIsBasicTypeOfTablePart(BaseTypeName, TypeNamesOfOwnersOfBasicTypesOfTableParts);

		EndIf;

	EndIf;

	Return ThisIsXDTOTypeOfTabularPart;

EndFunction

Function NamesOfBaseTypesOfComparedTypesOfXDTO()

	NamesOfBaseTypesOfComparedTypesOfXDTO = New Map();

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("AccountingRegisterRecord", NameOfBaseTypeAccountingRegister());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("AccumulationRegisterRecord", NameOfBaseTypeAccumulationRegister());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("BusinessProcessObject", NameOfBusinessProcessBaseType());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("BusinessProcessTabularSectionRow", NameOfBaseTypeBusinessProcessTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("CalculationRegisterRecord", NameOfBaseTypeCalculationRegister());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("CatalogObject", NameOfBaseTypeReference());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("CatalogTabularSectionRow", NameOfBaseTypeReferenceTablePart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ChartOfAccountsObject", NameOfBaseTypeChartOfAccounts());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ChartOfAccountsTabularSectionRow", NameOfBaseTypeChartOfAccountsTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ChartOfCalculationTypesObject", NameOfBaseTypeCalculationTypesPlan());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ChartOfCalculationTypesTabularSectionRow", NameOfBaseTypePlanOfCalculationTypesTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ChartOfCharacteristicTypesObject", NameOfBaseTypePlanOfTypesOfCharacteristics());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ChartOfCharacteristicTypesTabularSectionRow", NameOfBaseTypePlanOfTypesOfCharacteristicsTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ConstantValueManager", NameOfBaseTypeConstant());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("DocumentObject", NameOfBaseTypeDocument());	
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("DocumentTabularSectionRow", NameOfBaseTypeDocumentTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("InformationRegisterRecord", NameOfBaseTypeInformationRegister());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("SequenceRecord", NameOfBaseTypeSequence());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("TaskObject", NameOfBaseTypeTask());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("TaskTabularSectionRow", NameOfBaseTypeTaskTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ExchangePlanObject", ExchangePlanBaseTypeName());
	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("ExchangePlanTabularSectionRow", ExchangePlanBaseTypeNameTabularPart());

	NamesOfBaseTypesOfComparedTypesOfXDTO.Insert("EnumRef", BaseTypeNameEnumeration());

	Return NamesOfBaseTypesOfComparedTypesOfXDTO;

EndFunction

Function InformationAboutTypeOfObject(ObjectTypeName)

	PartsOfObjectType = StrSplit(ObjectTypeName, ".");

	If PartsOfObjectType.Count() < 2 Then

		Return Undefined;

	EndIf;

	PartsOfAppliedType = New Array;
	For IndexOf = 1 To PartsOfObjectType.UBound() Do

		PartsOfAppliedType.Add(PartsOfObjectType[IndexOf]);

	EndDo;

	Return New Structure("TypeNameXDTO, NameOfApplicationType",
		PartsOfObjectType[0],
		StrConcat(PartsOfAppliedType, "."));

EndFunction

Function MetadataObjectTemplateMissingInDestination()

	Return NStr("vi = 'Đối tượng metadata ''%1'' không có trong cấu hình cơ sở thông tin, nhưng lại có trong cấu hình kết xuất';
				|ru = 'Объект метаданных ''%1'' отсутствует в конфигурации информационной базы, но присутствует в конфигурации выгрузки';
				|en = 'The ''%1'' metadata object is missing from the infobase configuration but is found in the export configuration.'; fa = 'The ''%1'' metadata object is missing from the infobase configuration but is found in the export configuration.';
				|it = 'Oggetto di metadati ''%1'' assente nella configurazione dell''infobase, ma presente nella configurazione dell''upload';
				|pl = 'Brak obiektu metadanych ''%1'' nie ma w konfiguracji bazy informacyjnej, ale jest w konfiguracji eksportu';
				|tr = '""%1"" meta veri nesnesi infobase yapılandırmasında mevcut değil ama dışa aktarma yapılandırmasında mevcut'");

EndFunction

Function MetadataObjectTemplateMissingInSource()

	Return NStr("vi = 'Đối tượng metadata ''%1'' không có trong cấu hình kết xuất, nhưng có trong cấu hình cơ sở thông tin';
				|ru = 'Объект метаданных ''%1'' отсутствует в конфигурации выгрузки, но присутствует в конфигурации информационной базы';
				|en = 'The ''%1'' metadata object is missing from the export configuration but is found in the infobase configuration.'; fa = 'The ''%1'' metadata object is missing from the export configuration but is found in the infobase configuration.';
				|it = 'Oggetto di metadati ''%1'' assente nella configurazione di upload ma presente nella configurazione di infobase';
				|pl = 'Brak obiektu metadanych ''%1'' nie ma w konfiguracji eksportu, ale jest w konfiguracji bazy informacyjnej';
				|tr = '""%1"" meta veri nesnesi dışa aktarma yapılandırmasında mevcut değil ama infobase yapılandırmasında mevcut'");

EndFunction

Function ValueTemplateMissingInDestination()

	Return NStr("vi = 'Giá trị ''%1'' đối tượng metadata ''%2'' không có trong cấu hình cơ sở thông tin, nhưng có trong cấu hình kết xuất';
				|ru = 'Значение ''%1'' объекта метаданных ''%2'' отсутствует в конфигурации информационной базы, но присутствует в конфигурации выгрузки';
				|en = 'The ''%1'' value of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.'; fa = 'The ''%1'' value of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.';
				|it = 'Значение ''%1'' объекта метаданных ''%2'' отсутствует в конфигурации информационной базы, но присутствует в конфигурации выгрузки';
				|pl = 'The ''%1'' value of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.';
				|tr = '''%2'' meta veri nesnesinin ''%1'' değeri infobase tabanı yapılandırmasında yok, ancak dışa aktarma yapılandırmasında mevcut'");

EndFunction

Function TabularPartTemplateMissingInDestination()

	Return NStr("vi = 'Phần bảng ''%1'' đối tượng metadata ''%2'' không có trong cấu hình cơ sở thông tin, nhưng có trong cấu hình kết xuất';
				|ru = 'Табличная часть ''%1'' объекта метаданных ''%2'' отсутствует в конфигурации информационной базы, но присутствует в конфигурации выгрузки';
				|en = 'The ''%1'' table of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.'; fa = 'The ''%1'' table of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.';
				|it = 'Parte tabellare ''%1'' dell''oggetto di metadati ''%2'' assente nella configurazione di infobase ma presente nella configurazione di upload';
				|pl = 'Sekcji tabelarycznej ''%1'' obiektu metadanych ''%2'' nie ma w konfiguracji bazy informacyjnej, ale jest w konfiguracji eksportu';
				|tr = '""%2"" meta veri nesnesinin ""%1"" tablosu infobase yapılandırmasında mevcut değil ama dışa aktarma yapılandırmasında mevcut'");

EndFunction

Function TabularPartTemplateMissingInSource()

	Return NStr("vi = 'Phần bảng ''%1'' đối tượng metadata ''%2'' không có trong cấu hình kết xuất, nhưng có trong cấu hình cơ sở thông tin';
				|ru = 'Табличная часть ''%1'' объекта метаданных ''%2'' отсутствует в конфигурации выгрузки, но присутствует в конфигурации информационной базы';
				|en = 'The ''%1'' table of the ''%2'' metadata object is missing from the export configuration but is found in the infobase configuration.'; fa = 'The ''%1'' table of the ''%2'' metadata object is missing from the export configuration but is found in the infobase configuration.';
				|it = 'Parte tabellare ''%1'' dell''oggetto di metadati ''%2'' assente nella configurazione di upload ma presente nella configurazione di infobase';
				|pl = 'Sekcji tabelarycznej ''%1'' obiektu metadanych ''%2'' nie ma w konfiguracji eksportu, ale jest w konfiguracji bazy informacyjnej';
				|tr = '""%2"" meta veri nesnesinin ""%1"" tablosu dışa aktarma yapılandırmasında mevcut değil ama infobase yapılandırmasında mevcut'");

EndFunction

Function AttributeTemplateMissingInDestination()

	Return NStr("vi = 'Mục tin ''%1'' đối tượng metadata ''%2'' không có trong cấu hình cơ sở thông tin, nhưng có trong cấu hình kết xuất';
				|ru = 'Реквизит ''%1'' объекта метаданных ''%2'' отсутствует в конфигурации информационной базы, но присутствует в конфигурации выгрузки';
				|en = 'The ''%1'' attribute of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.'; fa = 'The ''%1'' attribute of the ''%2'' metadata object is missing from the infobase configuration but is found in the export configuration.';
				|it = 'Attributo ''%1'' dell''oggetto di metadati ''%2'' assente nella configurazione di infobase ma presente nella configurazione di upload';
				|pl = 'Atrybutu ''%1'' obiektu metadanych ''%2'' nie ma w konfiguracji bazy informacyjnej, ale jest w konfiguracji eksportu';
				|tr = '""%2"" meta veri nesnesinin ""%1"" özniteliği infobase yapılandırmasında mevcut değil ama dışa aktarma yapılandırmasında mevcut'");

EndFunction

Function AttributeTemplateMissingInSource()

	Return NStr("vi = 'Mục tin ''%1'' đối tượng metadata ''%2'' không có trong cấu hình kết xuất, nhưng có trong cấu hình cơ sở thông tin';
				|ru = 'Реквизит ''%1'' объекта метаданных ''%2'' отсутствует в конфигурации выгрузки, но присутствует в конфигурации информационной базы';
				|en = 'The ''%1'' attribute of the ''%2'' metadata object is missing from the export configuration but is found in the infobase configuration.'; fa = 'The ''%1'' attribute of the ''%2'' metadata object is missing from the export configuration but is found in the infobase configuration.';
				|it = 'Attributo ''%1'' dell''oggetto di metadati ''%2'' assente nella configurazione di upload ma presente nella configurazione di infobase';
				|pl = 'Atrybut ''%1'' obiektu metadanych ''%2'' nie ma w konfiguracji eksportu, ale jest w konfiguracji bazy informacyjnej';
				|tr = '""%2"" meta veri nesnesinin ""%1"" özniteliği dışa aktarma yapılandırmasında mevcut değil ama infobase yapılandırmasında mevcut'");

EndFunction

Function DifferentTablePartAttributeTypeTemplate()

	Return NStr("vi = 'Kiểu mục tin ''%1'' phần bảng ''%2'' đối tượng metadata ''%3'' trong cấu hình cơ sở thông tin khác với kiểu mục tin trong cấu hình kết xuất.';
				|ru = 'Тип реквизита ''%1'' табличной части ''%2'' объекта метаданных ''%3'' в конфигурации информационной базы отличается от типа в конфигурации выгрузки.';
				|en = 'The ''%1'' attribute type of the ''%2'' table of the ''%3'' metadata object in the infobase configuration differs from the type in the export configuration.'; fa = 'The ''%1'' attribute type of the ''%2'' table of the ''%3'' metadata object in the infobase configuration differs from the type in the export configuration.';
				|it = 'Tipo di attributo ''%1'' della parte tabellare ''%2'' dell''oggetto di metadati ''%3'' nella configurazione dell''infobase differisce dal tipo nella configurazione di upload.';
				|pl = 'Typ atrybutu ''%1'' sekcji tabelarycznej ''%2'' obiektu metadanych ''%3'' w konfiguracji bazy informacyjnej różni się od typu w konfiguracji eksportu.';
				|tr = 'Infobase yapılandırmasındaki ''%3'' meta veri nesnesinin ''%1'' tablo bölümünün ''%2'' öznitelik türü, dışa aktarma yapılandırmasındaki türden farklıdır.'")

EndFunction

Function DifferentAttributeTemplateType()

	Return NStr("vi = 'Kiểu mục tin ''%1'' đối tượng metadata ''%2'' trong cấu hình cơ sở thông tin khác với kiểu mục tin trong cấu hình kết xuất.';
				|ru = 'Тип реквизита ''%1'' объекта метаданных ''%2'' в конфигурации информационной базы отличается от типа в конфигурации выгрузки.';
				|en = 'The ''%1'' attribute of the ''%2'' metadata object in the infobase configuration differs from the type in the export configuration.'; fa = 'The ''%1'' attribute of the ''%2'' metadata object in the infobase configuration differs from the type in the export configuration.';
				|it = 'Tipo di attributo ''%1'' dell''oggetto di metadati ''%2'' nella configurazione di infobase differisce dal tipo nella configurazione di upload.';
				|pl = 'Typ atrybutu ''%1'' obiektu metadanych ''%2'' w konfiguracji bazy informacyjnej różni się od typu w konfiguracji eksportu.';
				|tr = 'Infobase yapılandırmasındaki ''%2'' meta veri nesnesinin ''%1'' öznitelik türü, dışa aktarma yapılandırmasındaki türden farklıdır.'");

EndFunction

#EndRegion