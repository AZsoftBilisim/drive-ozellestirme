
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	CASE WHEN VALUETYPE(Owner) = TYPE(Catalog.Projects)         OR VALUETYPE(Owner) = TYPE(Catalog.MarketingActivities)
	|	THEN ListReadingAllowed(Owner)
	|	WHEN VALUETYPE(Owner) = TYPE(Catalog.Complaints)
	|	THEN ValueAllowed(CAST(Owner AS Catalog.Complaints).Partner)
	|	ELSE ObjectReadingAllowed(Owner)
	|	END 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	CASE WHEN VALUETYPE(Owner) = TYPE(Catalog.Projects)         OR VALUETYPE(Owner) = TYPE(Catalog.MarketingActivities)
	|	THEN ListReadingAllowed(Owner)
	|	WHEN VALUETYPE(Owner) = TYPE(Catalog.Complaints)
	|	THEN ValueAllowed(CAST(Owner AS Catalog.Complaints).Partner)
	|	ELSE ObjectUpdateAllowed(Owner)
	|	END ";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf
