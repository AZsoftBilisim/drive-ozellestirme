

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// We will get the analytics of subordinate lines
	SubordinateDecryption = Parameters.SubordinateDecryption;
	DetailsData = GetFromTempStorage(Parameters.DetailsDataAddress);
	SubordinateAnalystValues = New Map();
	For Each DetailsIndex In SubordinateDecryption Do
		Details = DetailsData[DetailsIndex]; 
		For Each KeyValue In Details.AnalystValues Do
			If ValueIsFilled(KeyValue.Value) Then
				SubordinateAnalystValues.Insert(KeyValue.Key, KeyValue.Value);
			EndIf;
		EndDo;
	EndDo;

	ArrayOfAnalyticsTypes = Parameters.ArrayOfAnalyticsTypes;
	ArrayForGettingValues = Common.CopyRecursive(ArrayOfAnalyticsTypes);
	For Each KeyAndValue In Parameters.AnalystValues Do
		ArrayForGettingValues.Add(KeyAndValue.Key);
	EndDo;
	AnalystDetails = Common.ObjectsAttributesValues(ArrayForGettingValues, "Description, ValueType");
	Cnt = 0;
	
	For Each DimensionKind In ArrayOfAnalyticsTypes Do
		Cnt = Cnt + 1;
		ThisObject["DimensionKind" + Cnt] = DimensionKind;
		Attributes = AnalystDetails[DimensionKind];
		Items["Dimension" + Cnt].Title 		= Attributes.Description;
		Items["Dimension" + Cnt].TypeRestriction 	= Attributes.ValueType;
		ThisObject["Dimension" + Cnt] = BudgetingClientServer.ReducedAnalyticsValue(Undefined,
			Attributes.ValueType);
		
		If Attributes.ValueType.Types().Find(Type("CatalogRef.ObjectsPropertiesValues")) <> Undefined Then
			ChoiceParameter = New ChoiceParameter("Filter.Owner", DimensionKind.AdditionalProperty);
			Array = CommonClientServer.ValueInArray(ChoiceParameter);
			
			Items["Dimension" + Cnt].ChoiceParameters = New FixedArray(Array);
		EndIf;
		
		AddCommunicationParametersByOwner(Cnt, Attributes.ValueType, AnalystDetails, Parameters.AnalystValues, SubordinateAnalystValues);
		If ArrayOfAnalyticsTypes.Count() > 1 Then
			Items["Dimension" + Cnt].SetAction("OnChange", "DimensionOnChange");
		EndIf;
	EndDo;
	
	NumberOfTypesOfAnalytics = ArrayOfAnalyticsTypes.Count();
	
	If NumberOfTypesOfAnalytics > 1 Then
		For Cnt = NumberOfTypesOfAnalytics + 1 To 6 Do
			Items["Dimension" + Cnt].Visible = False;
		EndDo;
		ParametersOfAnalyticsTypes = New Structure("AnalystDetails, AnalystValues, SubordinateAnalystValues",
			AnalystDetails, Parameters.AnalystValues, SubordinateAnalystValues);
		Items.GroupListOfAnalysts.Visible = False;
	Else
		Items.AnalyticsGroupByLine.Visible = False;
		ListOfAnalysts.ValueType = AnalystDetails[ArrayOfAnalyticsTypes[0]].ValueType;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddRow(Command)
	
	ComplianceAnalyst = New Map;
	For Cnt = 1 To 6 Do
		DimensionKind = ThisObject["DimensionKind" + Cnt];
		If ValueIsFilled(DimensionKind) Then
			If NumberOfTypesOfAnalytics > 1 Or ListOfAnalysts.Count() = 0 Then
				ComplianceAnalyst.Insert(DimensionKind, ThisObject["Dimension" + Cnt]);
			ElsIf ListOfAnalysts.Count() = 1 Then
				ComplianceAnalyst.Insert(DimensionKind, ListOfAnalysts[0].Value);
			Else
				ComplianceAnalyst.Insert(DimensionKind, ListOfAnalysts.UnloadValues());
			EndIf;
		EndIf;
	EndDo;
	
	Close(ComplianceAnalyst);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DimensionOnChange(Item)
	
	For Cnt = 1 To NumberOfTypesOfAnalytics Do
		If Items["Dimension"+Cnt] = Item Then
			CurAnalyticsNumber = Cnt;
			Break;
		EndIf;
	EndDo;
	
	For Cnt = CurAnalyticsNumber To NumberOfTypesOfAnalytics Do
		AddCommunicationParametersByOwner(Cnt, Items["Dimension" + Cnt].TypeRestriction,
			ParametersOfAnalyticsTypes.AnalystDetails, ParametersOfAnalyticsTypes.AnalystValues,
			ParametersOfAnalyticsTypes.SubordinateAnalystValues);
	EndDo;
	
EndProcedure

&AtServer
Procedure AddCommunicationParametersByOwner(Cnt, ValueType, AnalystDetails, AnalystValues, SubordinateAnalystValues)
		
	OwnersCompliance = FinancialReportingCached.MatchingSelectionsByOwner();
	For Each Type In ValueType.Types() Do
		OwnerTypes = OwnersCompliance[Type];
		If OwnerTypes <> Undefined Then
			
			For CounterReverse = 1 To Cnt - 1 Do
				IndexOfVerifiableAnalytics = Cnt - CounterReverse;
				DimensionKind = ThisObject["DimensionKind" + IndexOfVerifiableAnalytics];
				Attributes = AnalystDetails[DimensionKind];
				For Each TypeRow In OwnerTypes Do
					If Attributes.ValueType.ContainsType(TypeRow.Type) Then
						If ValueIsFilled(ThisObject["Dimension" + IndexOfVerifiableAnalytics]) = 1 Then
							ParameterRelationships = New ChoiceParameterLink("Filter." + TypeRow.Attribute, "Dimension"
								+ IndexOfVerifiableAnalytics);
							Array = CommonClientServer.ValueInArray(ParameterRelationships);
							If TypeRow.Type = Type("CatalogRef.ItemKinds") Then
								Array.Add(New ChoiceParameterLink("FilterByTheProductKind", "OwnerOfAnalyst" + Cnt));
							EndIf;
						Else
							Array = New Array;
						EndIf;
						If NumberOfTypesOfAnalytics > 1 Then
							Items["Dimension" + Cnt].ChoiceParameterLinks = New FixedArray(Array);
						Else
							Items.DimensionsListValue.ChoiceParameterLinks = New FixedArray(Array);
						EndIf;
						Return;
					EndIf;
				EndDo;
			EndDo;
						
			// By subordinate line analysts
			For Each KeyAndValue In SubordinateAnalystValues Do
				DimensionKind = KeyAndValue.Key;
				Attributes = AnalystDetails[DimensionKind];
				For Each TypeRow In OwnerTypes Do
					If Attributes.ValueType.ContainsType(TypeRow.Type) Then
						If ValueIsFilled(KeyAndValue.Value) Then
							ThisObject["OwnerOfAnalyst" + Cnt] = KeyAndValue.Value;
							ParameterRelationships = New ChoiceParameterLink("Filter." + TypeRow.Attribute,
								"OwnerOfAnalyst" + Cnt);
							Array = CommonClientServer.ValueInArray(ParameterRelationships);
							If TypeRow.Type = Type("CatalogRef.ItemKinds") Then
								Array.Add(New ChoiceParameterLink("FilterByTheProductKind", "OwnerOfAnalyst" + Cnt));
							EndIf;
						Else
							Array = New Array;
						EndIf;
						If NumberOfTypesOfAnalytics > 1 Then
							Items["Dimension" + Cnt].ChoiceParameterLinks = New FixedArray(Array);
						Else
							Items.DimensionsListValue.ChoiceParameterLinks = New FixedArray(Array);
						EndIf;
						Return;
					EndIf;
				EndDo;
			EndDo;
			
			For Each KeyAndValue In AnalystValues Do
				DimensionKind = KeyAndValue.Key;
				Attributes = AnalystDetails[DimensionKind];
				For Each TypeRow In OwnerTypes Do
					If Attributes.ValueType.ContainsType(TypeRow.Type) Then
						If ValueIsFilled(KeyAndValue.Value) = 1 Then
							ThisObject["OwnerOfAnalyst" + Cnt] = KeyAndValue.Value;
							ParameterRelationships = New ChoiceParameterLink("Filter." + TypeRow.Attribute,
								"OwnerOfAnalyst" + Cnt);
							Array = CommonClientServer.ValueInArray(ParameterRelationships);
							If TypeRow.Type = Type("CatalogRef.ItemKinds") Then
								Array.Add(New ChoiceParameterLink("FilterByTheProductKind", "OwnerOfAnalyst" + Cnt));
							EndIf;
						Else
							Array = New Array;
						EndIf;
						If NumberOfTypesOfAnalytics > 1 Then
							Items["Dimension" + Cnt].ChoiceParameterLinks = New FixedArray(Array);
						Else
							Items.DimensionsListValue.ChoiceParameterLinks = New FixedArray(Array);
						EndIf;
						Return;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion