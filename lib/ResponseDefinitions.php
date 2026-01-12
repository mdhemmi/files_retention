<?php

declare(strict_types=1);

/**
 * SPDX-FileCopyrightText: 2025 Nextcloud GmbH and Nextcloud contributors
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

namespace OCA\Files_Retention;

/**
 * @psalm-type Files_RetentionRule = array{
 *     id: positive-int,
 *     tagid: positive-int,
 *     // 0 days, 1 weeks, 2 months, 3 years
 *     timeunit: 0|1|2|3,
 *     timeamount: positive-int,
 *     // 0 creation time, 1 modification time
 *     timeafter: 0|1,
 *     // 0 delete, 1 move to trash, 2 move to path
 *     actiontype: 0|1|2,
 *     // Destination path when actiontype is 2, null otherwise
 *     movetopath: string|null,
 *     hasJob: bool,
 * }
 */
class ResponseDefinitions {
}
