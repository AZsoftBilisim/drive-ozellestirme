#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a temporary table with a description of the details and details of the type of operations.
// The name of the table Dvoistvennosti.
//
// Parameters:
//  Ref					 - CatalogRef.TechnologicalOperationKinds - type of operation.
//  TempTablesManager	 - TempTablesManager - the Manager where the created temporary table will be placed.
//  ReadBankingDetails		 - Boolean - flag for getting Bank details.
//  ReadDetails		 - Boolean - flag for getting information.
//
Procedure CreateTTSetProperties(Ref, TempTablesManager, ReadBankingDetails, ReadDetails) Export
	
	Query = New Query(
		"SELECT
		|	SetsProperties.LineNumber     AS LineNumber,
		|	SetsProperties.Property        AS Property,
		|	SetsProperties.DeletionMark AS DeletionMark,
		|	ISNULL(Properties.Title, PRESENTATION(SetsProperties.Property)) AS Title,
		|	Properties.ValueType            AS ValueType,
		|	Properties.FormatProperties         AS FormatProperties,
		|	FALSE                            AS IsAdditionalInfo
		|INTO TTSetProperties
		|FROM
		|	Catalog.TechnologicalOperationKinds AS TechnologicalOperationKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetsProperties
		|		ON TechnologicalOperationKinds.PropertiesSet = SetsProperties.Ref
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
		|		ON (SetsProperties.Property = Properties.Ref)
		|WHERE
		|	TechnologicalOperationKinds.Ref = &Ref
		|	AND &ReadBankingDetails
		|
		|UNION ALL
		|
		|SELECT
		|	SetsProperties.LineNumber,
		|	SetsProperties.Property,
		|	SetsProperties.DeletionMark,
		|	ISNULL(Properties.Title, PRESENTATION(SetsProperties.Property)),
		|	Properties.ValueType,
		|	Properties.FormatProperties,
		|	TRUE
		|FROM
		|	Catalog.TechnologicalOperationKinds AS TechnologicalOperationKinds
		|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalInfo AS SetsProperties
		|		ON TechnologicalOperationKinds.PropertiesSet = SetsProperties.Ref
		|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS Properties
		|		ON (SetsProperties.Property = Properties.Ref)
		|WHERE
		|	TechnologicalOperationKinds.Ref = &Ref
		|	AND &ReadDetails");
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ReadBankingDetails", ReadBankingDetails);
	Query.SetParameter("ReadDetails", ReadDetails);
	
	Query.Execute();
	
EndProcedure

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

