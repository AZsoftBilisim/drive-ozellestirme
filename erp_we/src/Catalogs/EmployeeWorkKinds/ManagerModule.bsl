#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The current price for the type of work on a given date is determined.
// If no date is specified, the last specified value is returned.
//
// Parameters:
//	WorkKind - CatalogRef.EmployeeWorkKinds - type of work,
//	UpdateDate - Date - date of information,
//	LaborGrade - CatalogRef.LaborGrades, Undefined - qualification category.
//	Department - CatalogRef.BusinessStructure, Undefined -
//	Organization - CatalogRef.Companies, Undefined -
//
// Returns:
//  Number, Undefined - the current price or Undefined if no value is set.
// 
Function CurrentRateOfTypeOfWork(WorkKind, UpdateDate, LaborGrade = Undefined, Department = Undefined, Organization = Undefined) Export
	
	
	If Not ValueIsFilled(WorkKind) Then
		Return 0;
	EndIf;
	
	ParametersOfActivitiesKind = Common.ObjectAttributesValues(WorkKind, "RateAccordingToPayScale, RatePerHourWorked, LaborInput, LaborInputMultiplier");
	
	
	Filter = New Structure("WorkKind", WorkKind);
	
	UseLaborGradesOfEmployeeActivityRates = True;
	UseLaborGradesOfEmployeeActivityRates = GetFunctionalOption("UseLaborGradesOfEmployeeActivityRates");
	If UseLaborGradesOfEmployeeActivityRates And Not ValueIsFilled(LaborGrade) Then
		Filter.Insert("LaborGrade", Common.ObjectAttributeValue(WorkKind, "LaborGrade"));
	ElsIf UseLaborGradesOfEmployeeActivityRates Then
		Filter.Insert("LaborGrade", LaborGrade);
	EndIf;
	
	PricingStructure = InformationRegisters.EmployeeActivityRates.GetLast(UpdateDate, Filter);
	
	Rate_ = PricingStructure.Rate_;
	
	If ParametersOfActivitiesKind.RatePerHourWorked Then
		Rate_ = PricingStructure.Rate_ * ParametersOfActivitiesKind.LaborInput / ParametersOfActivitiesKind.LaborInputMultiplier;
	EndIf;
	
	Return Rate_;
	
EndFunction

// Is determined by the setting of the reflection in Boo. default accounting for the specified type of work.
//
// Parameters:
//   WorkKind - CatalogRef.EmployeeWorkKinds - Type of work.
//
// Returns:
//   Structure - For a description of the fields, see the resources of the register of information of Accounting Workers.
//
Function AccountingOfTypeOfWork(WorkKind) Export
	RegisterData = Undefined;
	BSKIntegration.FillInAccountingOfTypeOfWorkAccordingToRegister(RegisterData, WorkKind);
	Return RegisterData;
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Internal

// Labor intensity auto-completion parameters.
// 
// Parameters:
//  Object - CatalogObject.EmployeeWorkKinds
// 
// Returns:
//  Undefined, Structure - Auto-completion Parameters for Labor Input:
// * LaborInput - Number
// * LaborInputMultiplier - Number
Function AutoCompletionParametersForLaborInput(Object) Export
	
	AttributesValues = Common.ObjectAttributesValues(
		Object.UnitOfMeasure, "MeasuredValueType,Numerator,Denominator");
	
	If AttributesValues.MeasuredValueType = Enums.TypesOfMeasuredValues.Time
		And ValueIsFilled(AttributesValues.Numerator)
		And ValueIsFilled(AttributesValues.Denominator) Then
		
		Fraction = ProductionServer.Fraction(AttributesValues.Numerator, 3600 * AttributesValues.Denominator);
		ProductionServer.ReduceFraction(Fraction);
		
		Return New Structure("LaborInput,LaborInputMultiplier", Fraction.Numerator, Fraction.Denominator);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

#EndIf