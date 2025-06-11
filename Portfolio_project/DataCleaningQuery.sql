USE Portfolio;

/*
This file is for data cleaning queries
all the steps taken in the process are listed one by one
1. Standardise the date format
2. Populate the Address data
3. Breaking out Address into Individual Columns (Address, City, State)
4. Change Y and N to Yes and No in "Sold as Vacant" column
5. Remove duplicates
6. Remove unused columns
*/


SELECT *
FROM Portfolio..NashvilleHousingData;


-- Step 1: Standardise the SaleDate date format

SELECT SaleDate
FROM Portfolio..NashvilleHousingData;

UPDATE NashvilleHousingData
SET SaleDate = CONVERT(date, SaleDate)
WHERE SaleDate IS NOT NULL;

-- Step 2: Populate the Address data

SELECT *
FROM Portfolio..NashvilleHousingData
WHERE PropertyAddress IS NULL;

SELECT 
    a.ParcelID,
    a.UniqueID,
    a.PropertyAddress,
    b.PropertyAddress AS FilledAddress
FROM Portfolio..NashvilleHousingData as a
JOIN Portfolio..NashvilleHousingData as b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
    WHERE a.PropertyAddress IS NULL;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio..NashvilleHousingData AS a
JOIN Portfolio..NashvilleHousingData AS b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
    WHERE a.PropertyAddress IS NULL;


-- Step 3: Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM Portfolio..NashvilleHousingData
-- WHERE PropertyAddress IS NOT NULL;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS CityState
FROM NashvilleHousingData;

ALTER TABLE NashvilleHousingData
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(100);

UPDATE NashvilleHousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


SELECT OwnerAddress
FROM NashvilleHousingData;

SELECT 
    PARSENAME(REPLACE(OwnerAddress,',','.'), 3) as OOwnerSplitAddress,
    PARSENAME(REPLACE(OwnerAddress,',','.'), 2) as OwnerCity,
    PARSENAME(REPLACE(OwnerAddress,',','.'), 1) as OwnerState 
FROM NashvilleHousingData;

ALTER TABLE NashvilleHousingData
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerCity NVARCHAR(100),
    OwnerState NVARCHAR(50);

UPDATE NashvilleHousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-- Step 4: Change Y and N to Yes and No in "Sold as Vacant" column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousingData
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant;

SELECT SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 0 THEN 'No'
        WHEN SoldAsVacant = 1 THEN 'Yes'
        ELSE CAST(SoldAsVacant AS NVARCHAR(10))
    END AS SoldAsVacant
FROM NashvilleHousingData;

ALTER TABLE NashvilleHousingData
ALTER COLUMN SoldAsVacant NVARCHAR(10);

UPDATE NashvilleHousingData
SET SoldAsVacant = 
    CASE
        WHEN SoldAsVacant = 0 OR SoldAsVacant = '0' THEN 'No'
        WHEN SoldAsVacant = 1 OR SoldAsVacant = 'a' THEN 'Yes'
        ELSE CONVERT(NVARCHAR(10), SoldAsVacant)
    END;

-- Step 5: Remove duplicates

SELECT *, 
    ROW_NUMBER() OVER(
        PARTITION BY ParcelID,
                    PropertyAddress,
                    SalePrice,
                    SaleDate,
                    LegalReference
                    ORDER BY 
                        UniqueID) AS RowNum
FROM NashvilleHousingData
ORDER BY ParcelID;
-- this query will help us identify duplicates based on the specified columns

WITH RowNumCTE AS (
    SELECT *, 
        ROW_NUMBER() OVER(
            PARTITION BY ParcelID,
                        PropertyAddress,
                        SalePrice,
                        SaleDate,
                        LegalReference
                        ORDER BY 
                            UniqueID) AS RowNum
    FROM NashvilleHousingData
)
SELECT *
FROM RowNumCTE
WHERE RowNum > 1;
-- this gives us the list of all the duplicates in our table

-- Step 6: Remove unused columns

ALTER TABLE NashvilleHousingData
DROP COLUMN OwnerAddress,
    PropertyAddress,
    TaxDistrict

SELECT *
FROM NashvilleHousingData;