///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	Fields.Add("PredefinedSetName");
	Fields.Add("Description");
	Fields.Add("Ref");
	Fields.Add("Parent");
	
	StandardProcessing = False;
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		If Common.IsMainLanguage() Then
			Return;
		EndIf;
#Else
		If StrCompare(StandardSubsystemsClient.ClientParameter("DefaultLanguageCode"), CommonClient.DefaultLanguageCode()) = 0 Then
			Return;
		EndIf;
#EndIf
	
	If ValueIsFilled(Data.Parent) Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportClientServer = Common.CommonModule("NationalLanguageSupportClientServer");
			ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
		EndIf;
#Else
		If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportClientServer = CommonClient.CommonModule("NationalLanguageSupportClientServer");
			ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
		EndIf;
#EndIf
		Return;
	EndIf;
	
	If ValueIsFilled(Data.PredefinedSetName) Then
		SetName = Data.PredefinedSetName;
	Else
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		SetName = Common.ObjectAttributeValue(Data.Ref, "PredefinedDataName");
#Else
		SetName = "";
#EndIf
	EndIf;
	Presentation = UpperLevelSetPresentation(SetName, Data);
	
	StandardProcessing = False;
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Updates descriptions of predefined sets in
// parameters of additional attributes and info.
//
// Parameters:
//  HasChanges - Boolean - a return value. If recorded,
//                  True is set, otherwise, it does not change.
//
Procedure RefreshPredefinedSetsDescriptionsContent(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	PredefinedSets = PredefinedPropertiesSets();
	
	BeginTransaction();
	Try
		HasCurrentChanges = False;
		PreviousValue2 = Undefined;
		
		StandardSubsystemsServer.UpdateApplicationParameter(
			"StandardSubsystems.Properties.AdditionalDataAndAttributePredefinedSets",
			PredefinedSets, HasCurrentChanges, PreviousValue2);
		
		StandardSubsystemsServer.AddApplicationParameterChanges(
			"StandardSubsystems.Properties.AdditionalDataAndAttributePredefinedSets",
			?(HasCurrentChanges,
			  New FixedStructure("HasChanges", True),
			  New FixedStructure()) );
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If HasCurrentChanges Then
		HasChanges = True;
	EndIf;
	
EndProcedure

Procedure ProcessPropertiesSetsForMigrationToNewVersion(Parameters) Export
	
	PredefinedPropertiesSets = PropertyManagerCached.PredefinedPropertiesSets();
	ObjectsWithIssuesCount = 0;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Sets.Ref AS Ref,
		|	Sets.PredefinedDataName AS PredefinedDataName,
		|	Sets.AdditionalAttributes.(
		|		Property AS Property
		|	) AS AdditionalAttributes,
		|	Sets.AdditionalInfo.(
		|		Property AS Property
		|	) AS AdditionalInfo,
		|	Sets.Parent AS Parent,
		|	Sets.IsFolder AS IsFolder
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets AS Sets
		|WHERE
		|	Sets.Predefined = TRUE";
	Result = Query.Execute().Unload();
	
	For Each SetToUpdate In Result Do
		
		BeginTransaction();
		Try
			If Not ValueIsFilled(SetToUpdate.PredefinedDataName) Then
				RollbackTransaction();
				Continue;
			EndIf;
			If Not StrStartsWith(SetToUpdate.PredefinedDataName, "Delete") Then
				RollbackTransaction();
				Continue;
			EndIf;
			
			PrefixLength = StrLen("Delete");
			SetName = Mid(SetToUpdate.PredefinedDataName, PrefixLength + 1, StrLen(SetToUpdate.PredefinedDataName) - PrefixLength);
			NewSetDetails = PredefinedPropertiesSets.Get(SetName); // See Catalogs.AdditionalAttributesAndInfoSets.SetProperties
			If NewSetDetails = Undefined Then
				RollbackTransaction();
				Continue;
			EndIf;
			NewSet = NewSetDetails.Ref;
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AdditionalAttributesAndInfoSets");
			LockItem.SetValue("Ref", NewSet);
			Block.Lock();
			
			// Populate a new set.
			NewSetObject = NewSet.GetObject();
			If SetToUpdate.IsFolder <> NewSetObject.IsFolder Then
				RollbackTransaction();
				Continue;
			EndIf;
			For Each StringAttribute In SetToUpdate.AdditionalAttributes Do
				If Not ValueIsFilled(StringAttribute.Property) Then
					Continue;
				EndIf;
				NewStringAttributes = NewSetObject.AdditionalAttributes.Add();
				FillPropertyValues(NewStringAttributes, StringAttribute);
				NewStringAttributes.PredefinedSetName = NewSetObject.PredefinedSetName;
				
				// Update the property set depending on an additional attribute.
				Property = NewStringAttributes.Property;
				Block = New DataLock;
				LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo");
				LockItem.SetValue("Ref", Property);
				Block.Lock();
				
				ObjectProperty = Property.GetObject();
				If ObjectProperty = Undefined Then
					Continue;
				EndIf;
				
				If ObjectProperty.PropertiesSet = SetToUpdate.Ref Then
					ObjectProperty.PropertiesSet = NewSet;
				EndIf;
				
				For Each Dependence In ObjectProperty.AdditionalAttributesDependencies Do
					If Dependence.PropertiesSet = SetToUpdate.Ref Then
						Dependence.PropertiesSet = NewSet;
					EndIf;
				EndDo;
				InfobaseUpdate.WriteObject(ObjectProperty);
			EndDo;
			For Each StringInfo In SetToUpdate.AdditionalInfo Do
				NewStringInfo = NewSetObject.AdditionalInfo.Add();
				FillPropertyValues(NewStringInfo, StringInfo);
				NewStringInfo.PredefinedSetName = NewSetObject.PredefinedSetName;
			EndDo;
			
			If Not SetToUpdate.IsFolder Then
				AdditionalAttributesTable = NewSetObject.AdditionalAttributes.Unload();
				AdditionalAttributes = PropertyManager.PropertiesByAdditionalAttributesKind(
					AdditionalAttributesTable, Enums.PropertiesKinds.AdditionalAttributes);
				Labels = PropertyManager.PropertiesByAdditionalAttributesKind(
					AdditionalAttributesTable,Enums.PropertiesKinds.Labels);
				AttributesCount = AdditionalAttributes.Count();
				LabelCount      = Labels.Count();
				InfoCount   = NewSetObject.AdditionalInfo.FindRows(
					New Structure("DeletionMark", False)).Count();
				
				NewSetObject.AttributesCount = Format(AttributesCount, "NG=");
				NewSetObject.InfoCount   = Format(InfoCount, "NG=");
				NewSetObject.LabelCount      = Format(LabelCount, "NG=");
			EndIf;
			
			InfobaseUpdate.WriteObject(NewSetObject);
			
			// Clean up the old set.
			ObsoleteSetObject = SetToUpdate.Ref.GetObject();
			ObsoleteSetObject.AdditionalAttributes.Clear();
			ObsoleteSetObject.AdditionalInfo.Clear();
			ObsoleteSetObject.Used = False;
			
			InfobaseUpdate.WriteObject(ObsoleteSetObject);
			
			If SetToUpdate.IsFolder Then
				Query = New Query;
				Query.SetParameter("Parent", SetToUpdate.Ref);
				Query.Text = 
					"SELECT
					|	AdditionalAttributesAndInfoSets.Ref AS Ref
					|FROM
					|	Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
					|WHERE
					|	AdditionalAttributesAndInfoSets.Parent = &Parent
					|	AND AdditionalAttributesAndInfoSets.Predefined = FALSE";
				SetsToTransfer = Query.Execute().Unload(); // @skip-check query-in-loop - Batch data processing.
				For Each String In SetsToTransfer Do
					SetObject = String.Ref.GetObject();
					SetObject.Parent = NewSet;
					InfobaseUpdate.WriteObject(SetObject);
				EndDo;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý tập hợp thuộc tính %1 do nguyên nhân:
					|%2';
					|ru = 'Не удалось обработать набор свойств %1 по причине:
					|%2';
					|en = 'Couldn''t process the ""%1"" property set. Reason:
					|%2'; fa = 'Couldn''t process the ""%1"" property set. Reason:
					|%2';
					|it = 'Non è stato possibile elaborare il kit di proprietà %1 a causa di 
					|%2';
					|pl = 'Nie można przetworzyć zestawu właściwości %1 z powodu:
					|%2';
					|tr = '
					|%2Nedeniyle özellik seti işlenemedi:%1'"), 
					SetToUpdate.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Metadata.Catalogs.AdditionalAttributesAndInfoSets, SetToUpdate.Ref, MessageText);
		EndTry;
		
	EndDo;
	
	If ObjectsWithIssuesCount <> 0 Then
		MessageText = NStr("vi = 'Thủ tục %1 đã kết thúc bị lỗi. Không phải tất cả tập hợp thuộc tính đều cập nhật thành công.';
							|ru = 'Процедура %1 завершилась с ошибкой. Не все наборы свойств удалось обновить.';
							|en = 'Procedure %1 was completed with an error. Some property sets were not updated.'; fa = 'Procedure %1 was completed with an error. Some property sets were not updated.';
							|it = 'La procedura %1 è stata completata con errori. Non tutti i kit di proprietà sono stati aggiornati.';
							|pl = 'Procedura %1 zakończyła się błędem. Nie wszystkie zestawy właściwości zostały zaktualizowane.';
							|tr = '%1İşlem bir hata ile sona erdi. Tüm özellik setleri güncellenemedi.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "ProcessPropertiesSetsForMigrationToNewVersion");
		Raise MessageText;
	EndIf;
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

// Initial population.

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
	PropertyManagerOverridable.OnSetUpInitialItemsFilling(Settings);
	
	Settings.KeyAttributeName          = "Ref";
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	PropertyManagerOverridable.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	
EndProcedure


// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
//
// Parameters:
//  Object                  - CatalogObject.ContactInformationKinds - Object to populate.
//  Data                  - ValueTableRow - object filling data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	PropertyManagerOverridable.OnInitialItemFilling(Object, Data, AdditionalParameters);
	
EndProcedure

//



#EndRegion

#EndIf

#Region Private

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Function PredefinedPropertiesSets() Export
	
	SetsTree = New ValueTree;
	SetsTree.Columns.Add("Name");
	SetsTree.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	SetsTree.Columns.Add("Used");
	SetsTree.Columns.Add("Id");
	SSLSubsystemsIntegration.OnGetPredefinedPropertiesSets(SetsTree);
	PropertyManagerOverridable.OnGetPredefinedPropertiesSets(SetsTree);
	
	PredefinedData = PropertyManagerInternal.PredefinedPropertiesSets();
	PropertiesSetsDescriptions = PropertyManagerInternal.PropertiesSetsDescriptions(PredefinedData);
	Descriptions = PropertiesSetsDescriptions[CurrentLanguage().LanguageCode];
	
	PropertiesSets = New Map;
	For Each Set In SetsTree.Rows Do
		SetProperties = SetProperties(PropertiesSets, Set);
		For Each ChildOneSet In Set.Rows Do
			ChildSetProperties = SetProperties(PropertiesSets, ChildOneSet, SetProperties.Ref, Descriptions);
			SetProperties.ChildSets.Insert(ChildOneSet.Name, ChildSetProperties);
		EndDo;
		SetProperties.ChildSets = New FixedMap(SetProperties.ChildSets);
		PropertiesSets[SetProperties.Name] = New FixedStructure(PropertiesSets[SetProperties.Name]);
		PropertiesSets[SetProperties.Ref] = New FixedStructure(PropertiesSets[SetProperties.Ref]);
	EndDo;
	
	NameInUserLanguage = "Description" + "_" + CurrentLanguage().LanguageCode;
	HaveLanguageColumn = PredefinedData.Columns.Find(NameInUserLanguage) <> Undefined;
	
	For Each Set In PredefinedData Do
		
		If HaveLanguageColumn Then
			Description = ?(HaveLanguageColumn, Set[NameInUserLanguage], Set["Description"]);
		EndIf;
		
		If ValueIsFilled(Set.Parent) Then
			Parent = ReferenceToParent(Set.Parent);
			
			SetProperties = PropertiesSets.Get(Parent);
			ChildSetProperties = InitialFillSetProperties(PropertiesSets, Set, Parent, Description);
			SetProperties.ChildSets.Insert(Set.PredefinedSetName, ChildSetProperties);
			
		Else
			SetProperties = InitialFillSetProperties(PropertiesSets, Set, Set.Parent, Description);
		EndIf;
		
	EndDo;
	
	Return New FixedMap(PropertiesSets);
	
EndFunction

// For internal use only.
// 
// Parameters:
//  PropertiesSets - Map of KeyAndValue:
//     * Key - String, CatalogRef.AdditionalAttributesAndInfoSets
//     * Value - See New_SetProperties
//  Set - ValueTreeRow:
//     * Name           - String
//     * IsFolder     - Boolean
//     * Used  - Boolean
//     * Id - UUID
// 
// Returns:
//  Structure:
//     * Name            - String
//     * IsFolder      - Boolean
//     * Used   - Boolean
//     * Ref         - CatalogRef.AdditionalAttributesAndInfoSets
//     * Parent       - CatalogRef.AdditionalAttributesAndInfoSets
//     * ChildSets - Map of KeyAndValue:
//        ** Key - String
//        ** Value - See SetProperties
//     * Description   - String
//
Function SetProperties(PropertiesSets, Set, Parent = Undefined, Descriptions = Undefined) Export
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi trong thủ tục %1 của mô-đun chung %2.';
			|ru = 'Ошибка в процедуре %1 общего модуля %2.';
			|en = 'Error in procedure %1 of common module %2.'; fa = 'Error in procedure %1 of common module %2.';
			|it = 'Errore di procedura %1 del modulo comune %2.';
			|pl = 'Błąd w procedurze %1 wspólnego modułu %2.';
			|tr = '%2genel modülün %1prosedüründe hata.'"), 
		"WhenCreatingPredefinedPropertySets", "PropertyManagerOverridable")
		+ Chars.LF + Chars.LF;
	
	If Not ValueIsFilled(Set.Name) Then
		Raise ErrorTitle + NStr("vi = 'Chưa điền tên tập hợp thuộc tính.';
								|ru = 'Имя набора свойств не заполнено.';
								|en = 'The property set name is required.'; fa = 'The property set name is required.';
								|it = 'Il nome dell''insieme di proprietà non è compilato.';
								|pl = 'Nazwa zestawu właściwości nie jest wypełniona.';
								|tr = 'Özellik kümesi adı boş.'");
	EndIf;
	
	If PropertiesSets.Get(Set.Name) <> Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xác định tên tập hợp thuộc tính ""%1"".';
				|ru = 'Имя набора свойств ""%1"" уже определено.';
				|en = 'The property set name ""%1"" is already defined.'; fa = 'The property set name ""%1"" is already defined.';
				|it = 'Il nome dell''insieme di proprietà ""%1"" è già definito.';
				|pl = 'Nazwa zestawu właściwości ""%1"" jest wypełniona.';
				|tr = '""%1"" özellik kümesi adı zaten tanımlanmış.'"),
			Set.Name);
	EndIf;
	
	If Not ValueIsFilled(Set.Id) Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền tên định danh tập hợp thuộc tính ""%1"".';
				|ru = 'Идентификатор набора свойств ""%1"" не заполнен.';
				|en = 'The ID of the ""%1"" property set is required.'; fa = 'The ID of the ""%1"" property set is required.';
				|it = 'Identificatore dell''insieme di proprietà ""%1"" non è compilato.';
				|pl = 'Identyfikator zestawu właściwości „%1” nie jest wypełniony.';
				|tr = 'Özellik seti tanımlayıcısı ""%1"" boş.'"),
			Set.Name);
	EndIf;
	
	If Not Common.SeparatedDataUsageAvailable() Then
		SetRef = Set.Id;
	Else
		SetRef = GetRef(Set.Id);
	EndIf;
	
	If PropertiesSets.Get(SetRef) <> Undefined Then
		SetProperties = PropertiesSets.Get(SetRef); // See New_SetProperties
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên định danh ""%1"" của tập hợp thuộc tính
			           |""%2"" đã được dùng cho tập hợp ""%3"".';
			           |ru = 'Идентификатор ""%1"" набора свойств
			           |""%2"" уже используется для набора ""%3"".';
			           |en = 'The ID %1 of the
			           |""%2"" property set is already used for the ""%3"" property set.'; fa = 'The ID %1 of the
			           |""%2"" property set is already used for the ""%3"" property set.';
			           |it = 'Identificatore ""%1"" dell''insieme di proprietà 
			           |""%2"" è già utilizzato per l''insieme ""%3"".';
			           |pl = 'Identyfikator ""%1"" zestawu właściwości
			           |""%2"" jest już używany dla zestawu ""%3"".';
			           |tr = '
			           |""%2"" özellik kümesinin ""%1"" kimliği, ""%3"" özellik kümesi için zaten kullanılıyor.'"),
			Set.Id, Set.Name, SetProperties.Name);
	EndIf;
	
	SetProperties = New_SetProperties();
	SetProperties.Name            = Set.Name;
	SetProperties.IsFolder      = Set.IsFolder;
	SetProperties.Used   = Set.Used;
	SetProperties.Ref         = SetRef;
	SetProperties.Parent       = Parent;
	SetProperties.ChildSets = ?(Parent = Undefined, New Map, Undefined);
	
	If Descriptions = Undefined Then
		SetProperties.Description = UpperLevelSetPresentation(Set.Name);
	Else
		SetProperties.Description = Descriptions[Set.Name];
	EndIf;
	
	If Parent <> Undefined Then
		SetProperties = New FixedStructure(SetProperties);
	EndIf;
	PropertiesSets.Insert(SetProperties.Name,    SetProperties);
	PropertiesSets.Insert(SetProperties.Ref, SetProperties);
	
	Return SetProperties;
	
EndFunction

// For internal use only.
// 
// Returns:
//  Structure:
//     * Name            - String
//     * IsFolder      - Boolean
//     * Used   - Boolean
//     * Ref         - CatalogRef.AdditionalAttributesAndInfoSets
//     * Parent       - CatalogRef.AdditionalAttributesAndInfoSets
//     * ChildSets - Map of KeyAndValue:
//        ** Key - String
//        ** Value - See SetProperties
//     * Description   - String
//
Function InitialFillSetProperties(PropertiesSets, Set, Parent = Undefined, Description = Undefined)
	
	ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi trong thủ tục %1 của mô-đun chung %2.';
			|ru = 'Ошибка в процедуре %1 общего модуля %2.';
			|en = 'Error in procedure %1 of common module %2.'; fa = 'Error in procedure %1 of common module %2.';
			|it = 'Errore di procedura %1 del modulo comune %2.';
			|pl = 'Błąd w procedurze %1 wspólnego modułu %2.';
			|tr = '%2genel modülün %1prosedüründe hata.'")
		+ Chars.LF + Chars.LF, "OnInitialItemsFilling", "PropertyManagerOverridable");
	
	If Not ValueIsFilled(Set.PredefinedSetName) Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền %1 tập hợp thuộc tính.';
				|ru = '%1 набора свойств не заполнено.';
				|en = '%1 of property set is required.'; fa = '%1 of property set is required.';
				|it = '%1 kit di proprietà non compilato.';
				|pl = '%1 zestawu właściwości nie jest wypełniona.';
				|tr = '%1özellik seti doldurulmadı.'"), "PredefinedSetName");
	EndIf;
	
	If PropertiesSets.Get(Set.PredefinedSetName) <> Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xác định %1 tập hợp thuộc tính ""%2"" ';
				|ru = '%1 набора свойств ""%2"" уже определено.';
				|en = '%1 of property set ""%2"" is already defined.'; fa = '%1 of property set ""%2"" is already defined.';
				|it = '%1 kit di proprietà ""%2"" già definito.';
				|pl = '%1 zestawu właściwości ""%2"" jest już określona.';
				|tr = '""%2"" özellik seti%1 artık belirlendi.'"), 
			"PredefinedSetName", Set.PredefinedSetName);
	EndIf;
	
	If Not ValueIsFilled(Set.Ref) Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền tham chiếu của tập hợp thuộc tính ""%1""';
				|ru = 'Ссылка набора свойств ""%1"" не заполнен.';
				|en = 'Property set ""%1"" requires a reference.'; fa = 'Property set ""%1"" requires a reference.';
				|it = 'Collegamento del kit di proprietà ""%1"" non compilato.';
				|pl = 'Odnośnik zestawu właściwości „%1” nie jest wypełniony.';
				|tr = 'Özellik seti ""%1"" bağlantısı doldurulmadı.'"),
			Set.PredefinedSetName);
	EndIf;
	
	SetRef = Set.Ref;
	
	If PropertiesSets.Get(SetRef) <> Undefined Then
		SetProperties = PropertiesSets.Get(SetRef);
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tham chiếu ""%1"" của tập hợp thuộc tính
			           |""%2"" đã được dùng cho tập hợp ""%3"".';
			           |ru = 'Ссылка ""%1"" набора свойств
			           |""%2"" уже используется для набора ""%3"".';
			           |en = 'Reference ""%1"" specified in property set
			           |""%2"" is already used in set ""%3"".'; fa = 'Reference ""%1"" specified in property set
			           |""%2"" is already used in set ""%3"".';
			           |it = 'Collegamento ""%1"" del kit di proprietà 
			           |""%2"" già utilizzato per il kit ""%3"".';
			           |pl = 'Odnośnik ""%1"" zestawu właściwości
			           |""%2"" jest już używany dla zestawu ""%3"".';
			           |tr = '""%1"" özellik seti
			           | ""%2"" bağlantısı artık ""%3"" seti için kullanılıyor.'"),
			Set.Ref, Set.PredefinedSetName, SetProperties.PredefinedSetName);
	EndIf;
	
	Parent = ReferenceToParent(Parent);
	
	SetProperties = New_SetProperties();
	SetProperties.Name = Set.PredefinedSetName;
	SetProperties.IsFolder = Set.IsFolder;
	SetProperties.Used = Set.Used;
	SetProperties.Ref = SetRef;
	SetProperties.Parent = Parent;
	SetProperties.ChildSets = ?(Parent = Undefined, New Map, Undefined);

	If ValueIsFilled(Description) Then
		SetProperties.Insert("Description", Description);
	Else
		SetProperties.Insert("Description", Set["Description"]); 
	EndIf;
	
	SetProperties = New FixedStructure(SetProperties);
	PropertiesSets.Insert(SetProperties.Name, SetProperties);
	PropertiesSets.Insert(SetProperties.Ref, SetProperties);
	
	Return SetProperties;
	
EndFunction

// Returns:
//  Structure:
//   * Name - String
//   * IsFolder - Boolean
//   * Used - Undefined
//   * Ref - Undefined
//   * Parent - Undefined
//   * ChildSets - Undefined
//   * Description - String
//
Function New_SetProperties()
	
	SetProperties = New Structure;
	SetProperties.Insert("Name", "");
	SetProperties.Insert("IsFolder", False);
	SetProperties.Insert("Used", Undefined);
	SetProperties.Insert("Ref", Undefined);
	SetProperties.Insert("Parent", Undefined);
	SetProperties.Insert("ChildSets", Undefined);
	SetProperties.Insert("Description", "");
	
	Return SetProperties;

EndFunction

Function ReferenceToParent(Parent)
	
	If ValueIsFilled(Parent) Then
		
		If Not Common.SeparatedDataUsageAvailable() Then
			Return New UUID(Parent);
		EndIf;
			
			If TypeOf(Parent) = Type("String") Then
				Parent = GetRef(New UUID(Parent));
			ElsIf TypeOf(Parent) = Type("UUID") Then
				Parent = GetRef(Parent);
			EndIf;
		
	EndIf;
	
	Return Parent;
	
EndFunction

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ProcessPropertiesSetsForMigrationToNewVersion");
	
EndProcedure

#EndIf

// ACC:361-disable server code was not accessed.
Function UpperLevelSetPresentation(PredefinedItemName, SetProperties = Undefined)
	
	Presentation = "";
	Position = StrFind(PredefinedItemName, "_");
	FirstNamePart =  Left(PredefinedItemName, Position - 1);
	SecondNamePart = Right(PredefinedItemName, StrLen(PredefinedItemName) - Position);
	
	FullName = FirstNamePart + "." + SecondNamePart;
	
	MetadataObject = Metadata.FindByFullName(FullName);
	If MetadataObject = Undefined Then
		Return Presentation;
	EndIf;
	
	If ValueIsFilled(MetadataObject.ListPresentation) Then
		Presentation = MetadataObject.ListPresentation;
	ElsIf ValueIsFilled(MetadataObject.Synonym) Then
		Presentation = MetadataObject.Synonym;
	ElsIf SetProperties <> Undefined Then
		Presentation = SetProperties.Description;
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion