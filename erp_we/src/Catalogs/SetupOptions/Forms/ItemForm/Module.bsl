#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ChooseDesignColor();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ReadDesignColor(CurrentObject);
	
	OnReadCreateAtServer();	
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	SaveDesignColor(CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_SetupOptions",, Object.Owner);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	ManagingAvailabilityOfWorkTime();	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ManagingAvailabilityOfWorkTime();	
	
EndProcedure

&AtServer
Procedure ReadDesignColor(CurrentObject)

	ObjectDesignColor = CurrentObject.ColorOfDesign.Get();
	If ObjectDesignColor <> Undefined Then
		ColorOfDesign = ObjectDesignColor.ColorOfDesign;
	EndIf;

EndProcedure

&AtServer
Procedure ChooseDesignColor()

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	SetupOptions.ColorOfDesign
	|FROM
	|	Catalog.SetupOptions AS SetupOptions
	|WHERE
	|	NOT SetupOptions.DeletionMark
	|	AND SetupOptions.Owner = &Owner";
	
	Query.SetParameter("Owner", Object.Owner);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ColorsUsed = New Array;
	While Selection.Next() Do
		Storage = Selection.ColorOfDesign; // ValueStorage
		ColorAdjustmentOption = Storage.Get();
		If ColorAdjustmentOption <> Undefined Then
			ColorsUsed.Add(ColorAdjustmentOption);
		EndIf; 
	EndDo;
	
	ColorTemplate = Catalogs.SetupOptions.GetTemplate("Palette");
	For Cnt = 1 To ColorTemplate.TableHeight Do
		AppearanceArea = ColorTemplate.Area(Cnt, 1, Cnt, 1);
		If ColorsUsed.Find(AppearanceArea.BackColor) = Undefined Then
			ColorOfDesign = New ValueStorage(AppearanceArea.BackColor);
			Break;
		EndIf;
	EndDo;
		
EndProcedure

&AtServer
Procedure SaveDesignColor(CurrentObject)

	EmptyColor = New Color(0, 0, 0);
	If ColorOfDesign <> EmptyColor Then
		ObjectDesignColor = New Structure;
		ObjectDesignColor.Insert("ColorOfDesign", ColorOfDesign);
		ObjectDesignColor.Insert("RGBDesignColor", ProductionServer.ColorInRGBFormat(ColorOfDesign));
	Else
		ObjectDesignColor = Undefined;
	EndIf; 

	CurrentObject.ColorOfDesign = New ValueStorage(ObjectDesignColor);
	
EndProcedure

&AtServer
Procedure ManagingAvailabilityOfWorkTime()

	If Not Object.Owner.IsEmpty() Then
		DetailsOfRCType = Common.ObjectAttributesValues(Object.Owner, "ParallelLoad,ImportOption");
		OpeningHoursAvailable = (DetailsOfRCType.ParallelLoad 
								And DetailsOfRCType.ImportOption = Enums.WorkCenterLoadOptions.Synchronous);
	Else
		OpeningHoursAvailable = False;
	EndIf; 

	Items.OperationTime.Visible = OpeningHoursAvailable;
	Items.UnitOfMeasure.Visible = OpeningHoursAvailable;
	Items.OpeningHoursExplanation.Visible = OpeningHoursAvailable;
	
EndProcedure

#EndRegion
