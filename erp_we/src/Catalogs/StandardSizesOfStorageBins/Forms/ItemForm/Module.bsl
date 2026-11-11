
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then 
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NotLimitedByDimensionsOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure HeightOnChange(Item)
	
	RecalculateVolume();
	
EndProcedure

&AtClient
Procedure HeightUnitOfMeasureClick(Item, StandardProcessing)
	
	UnitOfMeasurementClick("HeightUnitOfMeasure",
							StandardProcessing,
							PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
	
EndProcedure

&AtClient
Procedure WidthOnChange(Item)
	
	RecalculateVolume();
	
EndProcedure

&AtClient
Procedure WidthUnitOfMeasureClick(Item, StandardProcessing)
	
	UnitOfMeasurementClick("WidthUnitOfMeasure",
							StandardProcessing,
							PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
	
EndProcedure

&AtClient
Procedure DepthOnChange(Item)
	
	RecalculateVolume();
	
EndProcedure

&AtClient
Procedure DepthUnitOfMeasureClick(Item, StandardProcessing)
	
	UnitOfMeasurementClick("DepthUnitOfMeasure",
							StandardProcessing,
							PredefinedValue("Enum.TypesOfMeasuredValues.Length"));
	
EndProcedure

&AtClient
Procedure VolumeUnitOfMeasureClick(Item, StandardProcessing)
	
	UnitOfMeasurementClick("VolumeUnitOfMeasure",
							StandardProcessing,
							PredefinedValue("Enum.TypesOfMeasuredValues.VolumeM3"));
	
EndProcedure

&AtClient
Procedure NotLimitedByCarryingCapacityOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure WeightUnitOfMeasureClick(Item, StandardProcessing)
	
	UnitOfMeasurementClick("WeightUnitOfMeasure",
							StandardProcessing,
							PredefinedValue("Enum.TypesOfMeasuredValues.Weight"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	FormControl();
	
EndProcedure

&AtServer
Procedure FormControl()
	
	Items.Height.Enabled		= Not Object.NotLimitedByDimensions;
	Items.Depth.Enabled	= Not Object.NotLimitedByDimensions;
	Items.Width.Enabled		= Not Object.NotLimitedByDimensions;
	Items.VolumeM3.Enabled		= Not Object.NotLimitedByDimensions;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.StandardSizesOfStorageBins);
	
	ItemsAvailability = CanBeEdited
							And Not Object.NotLimitedByDimensions;
	
	Items.HeightUnitOfMeasure.Enabled		= ItemsAvailability;
	Items.DepthUnitOfMeasure.Enabled	= ItemsAvailability;
	Items.WidthUnitOfMeasure.Enabled		= ItemsAvailability;
	Items.VolumeUnitOfMeasure.Enabled		= ItemsAvailability;
	
	Items.WeightUnitOfMeasure.Enabled	= CanBeEdited
													And Not Object.NotLimitedByCarryingCapacity;
	Items.CarryingCapacity.Enabled		= Not Object.NotLimitedByCarryingCapacity;
	
EndProcedure

&AtServer
Procedure RecalculateVolume()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CAST(&HeightUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&HeightUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientHeight,
	|	CAST(&WidthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&WidthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientWidth,
	|	CAST(&DepthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&DepthUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS CoefficientDepth,
	|	CAST(&VolumeUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Numerator / CAST(&VolumeUnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure).Denominator AS FactorVolume";
	
	Query.SetParameter("HeightUnitOfMeasure",		Object.HeightUnitOfMeasure);
	Query.SetParameter("WidthUnitOfMeasure",		Object.WidthUnitOfMeasure);
	Query.SetParameter("DepthUnitOfMeasure",	Object.DepthUnitOfMeasure);
	Query.SetParameter("VolumeUnitOfMeasure",		Object.VolumeUnitOfMeasure);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do 
		Object.VolumeM3 = Object.Height * Selection.CoefficientHeight * Object.Width * Selection.CoefficientWidth
						* Object.Depth * Selection.CoefficientDepth / Selection.FactorVolume;
	EndDo;
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClick(FieldName, StandardProcessing, MeasuredValueType)
	
	StandardProcessing = False;
	
	Filter				= New Structure("MeasuredValueType", MeasuredValueType);
	NotificationParameters	= New Structure("FieldName", FieldName);
	
	FormParameters		= New Structure("Filter", Filter);
	CallbackDescription	= New CallbackDescription("UnitOfMeasurementClickCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ChoiceForm",
				FormParameters,
				ThisObject,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UnitOfMeasurementClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then 
		Object[AdditionalParameters.FieldName] = Result;
		
		If AdditionalParameters.FieldName <> "WeightUnitOfMeasure" Then
			RecalculateVolume();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
