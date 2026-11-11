
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	OnReadCreateAtServer()
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.AdditionalProperties.Insert("ParentChangeIsAllowed");

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UnitOfMeasureTypeOnChange(Item)
	CustomizeForm();
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	CustomizeForm();
EndProcedure

&AtClient
Procedure QuantityInTheCurrentUnitOfMeasurementOnChange(Item)
	
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure QuantityInTheBaseUnitOfMeasurementOnChange(Item)
	
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.UnlockUnitAttributes",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        
        ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
        
    EndIf;

EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	CustomizeForm();
	RefreshFormTitle();
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	If Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Length
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Energy
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.ElectricCharge
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Capacity
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Time
		Or Object.MeasuredValueType = Enums.TypesOfMeasuredValues.NumberOfPieces Then
		Items.GroupMultiplicity.Visible = True;
		TitleDecorations = NStr("vi = '%UnitOfMeasure% =';
								|ru = '%UnitOfMeasure% =';
								|en = '%UnitOfMeasure% ='; fa = '%UnitOfMeasure% =';
								|it = '%UnitOfMeasure% =';
								|pl = '%UnitOfMeasure% =';
								|tr = '%UnitOfMeasure% ='");
		Items.Decoration1.Title = StrReplace(TitleDecorations, "%UnitOfMeasure%", Object.Description);
	Else 
		Items.GroupMultiplicity.Visible = False;
		Object.Numerator = 0;
		Object.Denominator = 0;
	EndIf;
	
	If Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Length Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'm';
												|ru = 'м';
												|en = 'm'; fa = 'متر';
												|it = 'm';
												|pl = 'm';
												|tr = 'm'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'm2';
												|ru = 'м2';
												|en = 'm2'; fa = 'm2';
												|it = 'm2';
												|pl = 'm2';
												|tr = 'm2'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.VolumeM3 Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'm3';
												|ru = 'м3';
												|en = 'm3'; fa = 'm3';
												|it = 'm3';
												|pl = 'm3';
												|tr = 'm3'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Weight Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'kg';
												|ru = 'кг';
												|en = 'kg'; fa = 'kg';
												|it = 'kg';
												|pl = 'kg';
												|tr = 'kg'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Energy Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'watt-giờ';
												|ru = 'ватт-час';
												|en = 'watt-hour'; fa = 'watt-hour';
												|it = 'Wh';
												|pl = 'watogodzina';
												|tr = 'watt-saat'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Capacity Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'watt';
												|ru = 'ватт';
												|en = 'watt'; fa = 'watt';
												|it = 'W';
												|pl = 'wat';
												|tr = 'watt'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.ElectricCharge Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'giờ ampe';
												|ru = 'ампер-час';
												|en = 'ampere-hour'; fa = 'ampere-hour';
												|it = 'Ah';
												|pl = 'amperogodzina';
												|tr = 'amper-saat'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.Time Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'từ';
												|ru = 'с';
												|en = 'sec'; fa = 'ثانیه';
												|it = 's';
												|pl = 's';
												|tr = 'ile'");
	ElsIf Object.MeasuredValueType = Enums.TypesOfMeasuredValues.NumberOfPieces Then
		PresentationOfBasicUnitOfMeasure = NStr("vi = 'chiếc';
												|ru = 'шт';
												|en = 'pcs'; fa = 'عدد';
												|it = 'шт';
												|pl = 'pcs';
												|tr = 'parça'");
	EndIf;
	
	MessageAboutMultiplicity = CheckMultiplicityOfNumericDetails(Object.Numerator, Object.Denominator);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	TypePresentation = NStr("vi = 'Đơn vị tính';
							|ru = 'Единица измерения';
							|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
							|it = 'Unità di misura';
							|pl = 'Jednosta miary';
							|tr = 'Ölçü birimi'");
	
	If Not ValueIsFilled(Object.Ref) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (tạo mới)';
				|ru = '%1 (создание)';
				|en = '%1 (Create)'; fa = '%1 (Create)';
				|it = '%1 (creazione)';
				|pl = '%1 (utworzenie)';
				|tr = '%1 (oluşturma)'"),
			TypePresentation);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2)';
				|ru = '%1 (%2)';
				|en = '%1 (%2)'; fa = '%1 (%2)';
				|it = '%1 (%2)';
				|pl = '%1 (%2)';
				|tr = '%1 (%2)'"),
			Object.Description,
			TypePresentation);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckMultiplicityOfNumericDetails(Numerator, Denominator)
	
	Result               = "";
	MessageMultiplicityMoreThan = NStr("vi = 'Hệ số lớn hơn 10 000 000 / 1';
										|ru = 'Кратность более 10 000 000 / 1';
										|en = 'Ratio exceeds 10,000,000:1'; fa = 'Ratio exceeds 10,000,000:1';
										|it = 'Il rapporto è maggiore di 10 000 000 / 1';
										|pl = 'Współczynnik ponad 10 000 000 / 1';
										|tr = 'Çarpım faktörü 10 000 000 / 1 fazla'");
	MessageMultiplicityLessThan = NStr("vi = 'Hệ số nhỏ hơn 1 / 99 999 999';
										|ru = 'Кратность менее 1 / 99 999 999';
										|en = 'Ratio is less than 1:99,999,999'; fa = 'Ratio is less than 1:99,999,999';
										|it = 'Il rapporto è minore di 1 / 99 999 999';
										|pl = 'Współczynnik poniżej 1 / 99 999 999';
										|tr = 'Çarpım faktörü 1 / 99 999 999 az'");
	
	If ValueIsFilled(Denominator) Then
		If Numerator / Denominator < 0.0000001 Then
			Result = MessageMultiplicityMoreThan;			
		ElsIf Numerator / Denominator > 99999999 Then
			Result = MessageMultiplicityLessThan;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
