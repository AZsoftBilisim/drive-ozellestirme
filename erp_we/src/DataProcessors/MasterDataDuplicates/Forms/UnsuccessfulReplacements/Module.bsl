#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FormattedHeader = StringFunctions.FormattedString(
		NStr("vi = '<b>Không thể thay thế</b> <a href=%1>%2</a> <b>sang</b> <a href=%3>%4</a> <b>trong một số nơi sử dụng:</b>';
			|ru = '<b>Не удалось заменить</b> <a href=%1>%2</a> <b>на</b> <a href=%3>%4</a> <b>в некоторых местах использования:</b>';
			|en = '<b>Cannot replace</b> <a href=%1>%2</a> <b>with</b> <a href=%3>%4</a><b>in some occurrences:</b>'; fa = '<b>Cannot replace</b> <a href=%1>%2</a> <b>with</b> <a href=%3>%4</a><b>in some occurrences:</b>';
			|it = '<b>Cannot replace</b> <a href=%1>%2</a> <b>with</b> <a href=%3>%4</a><b>in some occurrences:</b>';
			|pl = '<b>Cannot replace</b> <a href=%1>%2</a> <b>with</b> <a href=%3>%4</a><b>in some occurrences:</b>';
			|tr = '<b>Bazı kullanım yerlerinde</b> <a href=%1>%2</a> <b>ile</b> <a href=%3>%4</a> <b>değiştirilemedi:</b>'"),
		GetURL(Parameters.Duplicate1),
		String(Parameters.Duplicate1),
		GetURL(Parameters.Original),
		String(Parameters.Original));
	
	TreeRoot = UnprocessedItemsUsageInstances.GetItems();
	
	GroupingsIndex = New Map;
	
	For Each Error In Parameters.Errors Do
		BaseTypeName = Common.BaseTypeNameByMetadataObject(Error.ErrorObject.Metadata());
		
		If GroupingsIndex[BaseTypeName] = Undefined Then
			StringGrouping = TreeRoot.Add();
			StringGrouping.MetadataType = BaseTypeName;
			
			GroupingsIndex.Insert(StringGrouping.MetadataType, StringGrouping);
		Else
			StringGrouping = GroupingsIndex[BaseTypeName];
		EndIf;
		
		StringDecryption = StringGrouping.GetItems().Add();
		StringDecryption.ErrorObject = Error.ErrorObject;
		StringDecryption.ErrorText = Error.ErrorText;
		
		If BaseTypeName = "InformationRegisters" Then
			
			RegisterMetadata = Error.ErrorObject.Metadata();
			PresentationParts = New Array;
			ErrorObjectData = New Structure;
			KeyDetails = New Structure;
			
			// Period
			If RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
				Period = Error.ErrorObject.Period;
				KeyDetails.Insert("Period", Period);
				PresentationParts.Add(String(Period));
			EndIf;
			
			// Recorder
			If RegisterMetadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
				Recorder = Error.ErrorObject.Recorder;
				KeyDetails.Insert("Recorder", Recorder);
				PresentationParts.Add(String(Recorder));
			EndIf;
			
			// Dimensions
			ArrayOfDimensions_ = RegisterMetadata.Dimensions;
			For Each Dimension In ArrayOfDimensions_ Do
				DimensionName = Dimension.Name;
				DimensionValue = Error.ErrorObject[DimensionName];
				KeyDetails.Insert(DimensionName, DimensionValue);
				If ValueIsFilled(DimensionValue) Then
					PresentationParts.Add(String(DimensionValue));
				Else
					PresentationParts.Add("");
				EndIf;
			EndDo;
			
			Presentation = StrConcat(PresentationParts, ", ");
			ErrorObjectData.Insert("RegisterName", RegisterMetadata.Name);
			ErrorObjectData.Insert("KeyDetails", KeyDetails);
			StringDecryption.ErrorObjectData = ErrorObjectData;
			StringDecryption.ErrorObject = StrTemplate("%1 (%2)", Presentation, String(Error.ErrorObject));
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUnprocessedItemsUsageInstances

&AtClient
Procedure UnprocessedItemsUsageInstancesOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.ErrorText) Then
		
		ErrorDetailedInfo = "";
		Return;
	EndIf;
	
	ErrorDetailedInfo = StrTemplate(NStr("vi = 'Không thể thay thế do:
		|%1';
		|ru = 'Не удалось заменить по причине:
		|%1';
		|en = 'Cannot replace. Reason:
		|%1'; fa = 'Cannot replace. Reason:
		|%1';
		|it = 'Cannot replace. Reason:
		|%1';
		|pl = 'Cannot replace. Reason:
		|%1';
		|tr = 'Şu nedenden dolayı değiştirilemedi: 
		|%1'"), CurrentData.ErrorText);
	
EndProcedure

&AtClient
Procedure UnprocessedItemsUsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.UnprocessedItemsUsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If ValueIsFilled(CurrentData.ErrorObjectData) Then
		
		ErrorObjectData = CurrentData.ErrorObjectData;
		RegisterName = ErrorObjectData.RegisterName;
		
		DimensionStructure = New Structure;
		For Each KeyField In ErrorObjectData.KeyDetails Do
			DimensionStructure.Insert(KeyField.Key, KeyField.Value);
		EndDo;
		
		ArrayOfConstructorParameters = New Array();
		ArrayOfConstructorParameters.Add(DimensionStructure);
		RecordKey = New("InformationRegisterRecordKey." + RegisterName, ArrayOfConstructorParameters);
		FormParameters = New Structure("Key", RecordKey);
		
		FormPath = "InformationRegister." + RegisterName + ".RecordForm";
		OpenForm(FormPath, FormParameters, , , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		ShowValue(, CurrentData.ErrorObject);
	EndIf;
	
EndProcedure

#EndRegion
