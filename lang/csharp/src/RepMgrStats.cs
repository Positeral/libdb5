/*-
 * See the file LICENSE for redistribution information.
 *
 * Copyright (c) 2009, 2013 Oracle and/or its affiliates.  All rights reserved.
 *
 */
using System;
using System.Collections.Generic;
using System.Text;

namespace BerkeleyDB {
    /// <summary>
    /// Statistical information about the Replication Manager
    /// </summary>
    public class RepMgrStats {
        private Internal.RepMgrStatStruct st;
        internal RepMgrStats(Internal.RepMgrStatStruct stats) {
            st = stats;
        }

        /// <summary>
        /// Existing connections dropped. 
        /// </summary>
        public ulong DroppedConnections { get { return st.st_connection_drop; } }
        /// <summary>
        /// # msgs discarded due to excessive queue length.
        /// </summary>
        public ulong DroppedMessages { get { return st.st_msgs_dropped; } }
        /// <summary>
        /// Failed new connection attempts. 
        /// </summary>
        public ulong FailedConnections { get { return st.st_connect_fail; } }
        /// <summary>
        /// # of insufficiently ack'ed msgs. 
        /// </summary>
        public ulong FailedMessages { get { return st.st_perm_failed; } }
        /// <summary>
        /// # msgs queued for network delay. 
        /// </summary>
        public ulong QueuedMessages { get { return st.st_msgs_queued; } }
        /// <summary>
        /// Number of currently active election threads
        /// </summary>
        public ulong ElectionThreads { get { return st.st_elect_threads; } }
        /// <summary>
        /// Election threads for which space is reserved
        /// </summary>
        public ulong MaxElectionThreads { get { return st.st_max_elect_threads; } }

    }
}
